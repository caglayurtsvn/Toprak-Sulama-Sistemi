#include <ESP8266WiFi.h>
#include <ESP8266WebServer.h>

// Wi-Fi bilgileri
const char* ssid = "Cagla's Galaxy A24";
const char* password = "cagllayyurt";

// Web sunucu (port 80)
ESP8266WebServer server(80);

// Donanım pin tanımları
const int pumpPin = 5;         // Pompa D1 (GPIO5)RÖLE PİNİ
const int soilSensorPin = A0;  // Toprak nem sensörü A0 (Analog pin)

// Sensör kalibrasyon değerleri (Kuru → 1023, Tam Islak → 0)
const int DRY_VALUE = 1023;    // Sensörün kuru topraktaki ham değeri
const int WET_VALUE = 0;       // Sensörün tam ıslak topraktaki ham değeri

// CORS başlıkları ekle (Flutter erişimi için)
void sendCorsHeaders() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "*");
}

void setup() {
  Serial.begin(9600);

  pinMode(pumpPin, OUTPUT);
  digitalWrite(pumpPin, HIGH); // Pompa başlangıçta kapalı

  // Wi-Fi ağına bağlan
  WiFi.begin(ssid, password);
  Serial.print("Wi-Fi bağlanıyor...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("");
  Serial.print("Cihaz IP adresi: ");
  Serial.println(WiFi.localIP());

  // /sensor endpoint (nem ölçümü)
  server.on("/sensor", HTTP_GET, []() {
    sendCorsHeaders();
    int raw = analogRead(soilSensorPin);
    int nem = map(raw, DRY_VALUE, WET_VALUE, 0, 100); // 0-100% aralığı
    String response = "{\"raw\":" + String(raw) + ", \"nem\":" + String(nem) + "}";
    server.send(200, "application/json", response);
  });

  // /sula endpoint (pompa çalıştırma)
  server.on("/sula", HTTP_GET, []() {
    sendCorsHeaders();
    digitalWrite(pumpPin, LOW);  // Pompayı aç
    delay(5000);                 // 5 saniye çalıştır
    digitalWrite(pumpPin, HIGH); // Pompayı kapat
    server.send(200, "application/json", "{\"status\":\"Sulama tamamlandı\"}");
  });

  // CORS için OPTIONS methodu yakalama
  server.onNotFound([]() {
    if (server.method() == HTTP_OPTIONS) {
      sendCorsHeaders();
      server.send(204);
    } else {
      server.send(404, "text/plain", "Not found");
    }
  });

  // Web sunucuyu başlat
  server.begin();
}

void loop() {
  server.handleClient();

  // Seri monitörden nem değerlerini debug için yazdır
  static unsigned long lastRead = 0;
  if (millis() - lastRead > 2000) {
    lastRead = millis();
    int raw = analogRead(soilSensorPin);
    int nem = map(raw, DRY_VALUE, WET_VALUE, 0, 100);
    Serial.print("Nem: ");
    Serial.print(nem);
    Serial.print("%, Raw: ");
    Serial.println(raw);
  }
}