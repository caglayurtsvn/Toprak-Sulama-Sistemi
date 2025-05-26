import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SaksicanPage(),
    );
  }
}

class SaksicanPage extends StatefulWidget {
  @override
  _SaksicanPageState createState() => _SaksicanPageState();
}

class _SaksicanPageState extends State<SaksicanPage> {
  // Nem Sensörü Parametreleri (ESP8266 ile tam uyumlu)
  int rawValue = 0;       // ESP'den gelen raw değer (0-1023)
  int moisturePercent = 0; // ESP'den gelen nem yüzdesi (0-100)

  // Orijinal kodun geri kalanı (değiştirilmedi)
  List<String> papatyaBilgileri = [
    "Papatyalar güneşi sever! ☀️",
    "Papatya kökleri 1 metre derine inebilir! 🌱",
    "Papatyalar yaz aylarında açar! 🌼",
    "Papatya çayı sakinleştiricidir! 🍵",
    "Çiçekler fotosentezle oksijen üretir! 🌿",
    "Arılar, çiçeklerden nektar toplarken bitkilerin çoğalmasına yardım eder! 🐝",
    "Ayçiçekleri güneşe döner! 🌻",
    "Lavanta çiçekleri sakinleştirici etki yapar! 💜",
    "Güller sevginin simgesidir! 🌹",
  ];
  
  // Yeni eklenen sorular
  List<Map<String, dynamic>> cicekSorulari = [
    {
      "soru": "Papatyaların ürettiği, arıların sevdiği nedir?",
      "cevap": "polen",
      "ipucu": "Arıların sevdiği...",
      "dogruCevapMesaj": "Doğru! 🎉 Papatyalar arıları polenle çeker!"
    },
    {
      "soru": "Hangi çiçek güneşe doğru döner?",
      "cevap": "ayçiçeği",
      "ipucu": "İsmi güneşle ilgili...",
      "dogruCevapMesaj": "Harika! 🌻 Ayçiçekleri güneşi takip eder!"
    },
    {
      "soru": "Hangi çiçek genellikle sevginin sembolüdür?",
      "cevap": "gül",
      "ipucu": "Kırmızı olanı meşhur...",
      "dogruCevapMesaj": "Mükemmel! 🌹 Güller aşkın sembolüdür!"
    },
    {
      "soru": "Hangi çiçek mor rengi ve sakinleştirici özelliği ile bilinir?",
      "cevap": "lavanta",
      "ipucu": "Mor renkli ve kokusu güzel...",
      "dogruCevapMesaj": "Süper! 💜 Lavanta stresi azaltır!"
    },
    {
      "soru": "Hangi çiçek su üzerinde yetişir?",
      "cevap": "nilüfer",
      "ipucu": "Göllerde yetişen bir çiçek...",
      "dogruCevapMesaj": "Doğru! 🌸 Nilüferler suyun üzerinde açar!"
    },
  ];
  
  int mevcutSoruIndex = 0;
  String seciliBilgi = "";
  TextEditingController cevapController = TextEditingController();
  String bulmacaSonuc = "";
  final String esp8266Ip = "192.168.245.115";
  bool isSulamaYapiliyor = false;
  String sensorVerisi = "Henüz alınmadı";

  @override
  void initState() {
    super.initState();
    _rastgeleBilgiSec();
    _sensorVerileriniGetir();
  }

  void _rastgeleBilgiSec() {
    final random = Random();
    setState(() {
      seciliBilgi = papatyaBilgileri[random.nextInt(papatyaBilgileri.length)];
    });
  }

  void _bulmacaKontrol() {
    String cevap = cevapController.text.toLowerCase();
    if (cevap == cicekSorulari[mevcutSoruIndex]["cevap"]) {
      setState(() {
        bulmacaSonuc = cicekSorulari[mevcutSoruIndex]["dogruCevapMesaj"];
        // Doğru cevap verildiğinde bir sonraki soruya geç
        mevcutSoruIndex = (mevcutSoruIndex + 1) % cicekSorulari.length;
      });
    } else {
      setState(() {
        bulmacaSonuc = "Yanlış 😢 İpucu: ${cicekSorulari[mevcutSoruIndex]["ipucu"]}";
      });
    }
    cevapController.clear();
  }

  Future<void> _sulamaYap() async {
    setState(() {
      isSulamaYapiliyor = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://$esp8266Ip/sula'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Sulama Tamam! 💧"),
            content: Text("Bitkin Sulandı 💖 "),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Tamam"),
              )
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Hata!"),
            content: Text("ESP8266 ile iletişim kurulamadı"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Tamam"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Hata!"),
          content: Text("ESP8266 bağlantı hatası: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tamam"),
            )
          ],
        ),
      );
    } finally {
      setState(() {
        isSulamaYapiliyor = false;
      });
      _sensorVerileriniGetir();
    }
  }

  Future<void> _sensorVerileriniGetir() async {
    try {
      final response = await http.get(
        Uri.parse('http://$esp8266Ip/sensor'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          // ESP ile uyumlu parametre atamaları
          rawValue = data['raw']; 
          moisturePercent = data['nem'];
          sensorVerisi = "Nem: $moisturePercent%, (Raw: $rawValue)";
        });
      } else {
        setState(() {
          sensorVerisi = "Hata: Geçerli veri alınamadı.";
        });
      }
    } catch (e) {
      setState(() {
        sensorVerisi = "Bağlantı hatası: $e";
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[400],
      appBar: AppBar(
        title: Text("Papatya Bilgisi 🌸"),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  seciliBilgi,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                Text(
                  'SaksıCan',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Icon(
                  Icons.local_florist,
                  size: 100,
                  color: Colors.yellow,
                ),
                SizedBox(height: 30),
                Text(
                  "Sensor Verisi: $sensorVerisi",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: isSulamaYapiliyor ? null : _sulamaYap,
                  child: isSulamaYapiliyor
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(width: 10),
                            Text("Sulama Yapılıyor..."),
                          ],
                        )
                      : Text(
                          'SULA',
                          style: TextStyle(fontSize: 20),
                        ),
                ),
                SizedBox(height: 40),
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Mini Bulmaca: ${cicekSorulari[mevcutSoruIndex]["soru"]}",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: cevapController,
                        decoration: InputDecoration(
                          hintText: "Cevabı yaz...",
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _bulmacaKontrol,
                        child: Text("Kontrol Et"),
                      ),
                      SizedBox(height: 10),
                      Text(
                        bulmacaSonuc,
                        style: TextStyle(
                          color: bulmacaSonuc.contains("Doğru") || 
                                 bulmacaSonuc.contains("Harika") ||
                                 bulmacaSonuc.contains("Mükemmel") ||
                                 bulmacaSonuc.contains("Süper")
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}