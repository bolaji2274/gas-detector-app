// ==================== COMPLETE ESP32 GAS DETECTOR - MQ-6 SENSOR ====================
// Full working code with WiFi provisioning, Firebase integration, and MQ-6 sensor monitoring

#include <WiFi.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <Preferences.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// ==================== PIN CONFIGURATION ====================
#define MQ6_PIN 34          // MQ-6 Gas Sensor (Analog) - LPG, Propane, Butane
#define BUZZER_PIN 25       // Active Buzzer for alarm
#define LED_PIN 2           // Status LED
#define RELAY_PIN 26        // Optional relay for exhaust fan/ventilation
// OLED Display Configuration
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define SCREEN_ADDRESS 0x3C  // Try 0x3D if 0x3C doesn't work

// ==================== DISPLAY CONFIGURATION ====================
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// I2C Pins (ESP32 default)
#define SDA_PIN 21
#define SCL_PIN 22
// Display timing
unsigned long lastOLEDUpdate = 0;
const unsigned long OLED_UPDATE_INTERVAL = 1000;  // Update every 1 second  


// ==================== FIREBASE CONFIGURATION ====================
// IMPORTANT: Update this with your actual Firebase project URL
const char* firebaseFunctionUrl = "https://us-central1-gas-detection-system-30cc0.cloudfunctions.net";

// ==================== DEVICE CONFIGURATION ====================
String deviceId;
String deviceName = "Gas Detector";

// ==================== WIFI AP CONFIGURATION ====================
const char* AP_SSID_PREFIX = "GasDetector_";
const char* AP_PASSWORD = "12345678";

// ==================== GAS THRESHOLDS (PPM) ====================
// MQ-6 is optimized for LPG, Propane, Butane detection (200-10000 PPM)
const int THRESHOLD_SAFE = 300;
const int THRESHOLD_WARNING = 1000;
const int THRESHOLD_DANGER = 2500;
const int THRESHOLD_CRITICAL = 5000;

// ==================== TIMING INTERVALS ====================
const unsigned long SENSOR_READ_INTERVAL = 2000;      // Read sensor every 2 seconds
const unsigned long FIREBASE_UPDATE_INTERVAL = 5000;  // Update Firebase every 5 seconds
const unsigned long HEARTBEAT_INTERVAL = 30000;       // Send heartbeat every 30 seconds
const unsigned long BUZZER_BEEP_INTERVAL = 500;       // Buzzer beep interval

// ==================== OBJECTS ====================
WebServer server(80);
DNSServer dnsServer;
Preferences preferences;
HTTPClient http;

// ==================== STATE VARIABLES ====================
bool isConfigured = false;
bool wifiConnected = false;
String savedSSID = "";
String savedPassword = "";
String authToken = "";

// Sensor data
int gasLevel = 0;
int rawAnalogValue = 0;
String currentStatus = "safe";
int statusCode = 0;
String previousStatus = "safe";

// Timing
unsigned long lastSensorRead = 0;
unsigned long lastFirebaseUpdate = 0;
unsigned long lastHeartbeat = 0;
unsigned long lastBuzzerToggle = 0;

// Alarm state
bool alarmActive = false;
bool buzzerState = false;

// ==================== SETUP ====================
void setup() {
  Serial.begin(115200);
  delay(1000);

  // ADD THIS NEW CODE HERE:
  // Initialize I2C for OLED
  Wire.begin(SDA_PIN, SCL_PIN);

  // Initialize OLED Display
  if (!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    Serial.println("❌ OLED NOT FOUND!");
    Serial.println("Check wiring:");
    Serial.println("  SDA → GPIO 21");
    Serial.println("  SCL → GPIO 22");
    Serial.println("  VCC → 3.3V");
    Serial.println("  GND → GND");
    Serial.println("Trying alternative address 0x3D...");

    // Try alternative address
    if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3D)) {
      Serial.println("❌ OLED still not found at 0x3D");
      Serial.println("Continuing without OLED...");
    } else {
      Serial.println("✓ OLED found at 0x3D!");
      displayStartupScreen();
    }

    // Continue without OLED if not found
  } else {
    Serial.println("✓ OLED Display initialized at 0x3C");
    displayStartupScreen();
    
  }


  
  Serial.println("\n\n========================================");
  Serial.println("   MQ-6 GAS DETECTOR SYSTEM");
  Serial.println("========================================");
  
  // Initialize pins
  pinMode(MQ6_PIN, INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  pinMode(RELAY_PIN, OUTPUT);
  
  // Set initial states
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(LED_PIN, LOW);
  digitalWrite(RELAY_PIN, LOW);
  
  // Generate unique Device ID from ESP32 chip MAC
  uint64_t chipid = ESP.getEfuseMac();
  deviceId = "GD_" + String((uint32_t)(chipid >> 32), HEX) + String((uint32_t)chipid, HEX);
  deviceId.toUpperCase();


  // ADD THESE 3 LINES:
  Serial.println("  Device ID: " + deviceId);
  displayDeviceID();  // Show on OLED
//   delay(10000);       // Keep it visible for 10 seconds
  delay(5000);        // Keep it visible for 5 seconds
  
  Serial.println("\nDevice Information:");
  Serial.println("  Device ID: " + deviceId);
  Serial.println("  Sensor: MQ-6 (LPG/Propane/Butane)");
  Serial.println("  Firmware: v1.0.0");
  
  // Load saved WiFi credentials from flash memory
  preferences.begin("wifi-config", false);
  savedSSID = preferences.getString("ssid", "");
  savedPassword = preferences.getString("password", "");
  isConfigured = preferences.getBool("configured", false);
  authToken = preferences.getString("authToken", "");
  preferences.end();
  
  Serial.println("\nWiFi Configuration:");
  Serial.println("  Status: " + String(isConfigured ? "Configured" : "Not Configured"));
  if (isConfigured) {
    Serial.println("  Saved SSID: " + savedSSID);
  }
  
  // Try to connect to saved WiFi
  if (isConfigured && savedSSID.length() > 0) {
    Serial.println("\nAttempting WiFi connection...");
    connectToWiFi(savedSSID, savedPassword);
  }
  
  // If not connected, start AP mode for configuration
  if (!wifiConnected) {
    startAPMode();
  }
  
  // Warm up MQ-6 sensor (important for accurate readings)
  Serial.println("\n⏳ Warming up MQ-6 sensor...");
  Serial.println("   (Please wait 30 seconds for stabilization)");
  
  for (int i = 30; i > 0; i--) {
    Serial.print("   " + String(i) + " seconds remaining...\r");
    digitalWrite(LED_PIN, (i % 2) == 0 ? HIGH : LOW); // Blink LED during warmup
    delay(1000);
  }
  
  digitalWrite(LED_PIN, LOW);
  Serial.println("\n✓ Sensor ready!                          ");
  
  Serial.println("\n========================================");
  Serial.println("   SYSTEM READY - MONITORING STARTED");
  Serial.println("========================================\n");
}

// ==================== MAIN LOOP ====================
void loop() {
  // Handle DNS requests in AP mode (for captive portal)
  if (!wifiConnected) {
    dnsServer.processNextRequest();
  }
  
  // Handle web server requests
  server.handleClient();
  
  // Read sensor periodically
  if (millis() - lastSensorRead >= SENSOR_READ_INTERVAL) {
    lastSensorRead = millis();
    readSensor();
    updateStatusLED();
  }
  
  // Handle alarm system (continuous monitoring)
  handleAlarm();

  // ADD THIS NEW CODE HERE:
  // Update OLED display
  if (millis() - lastOLEDUpdate >= OLED_UPDATE_INTERVAL) {
    lastOLEDUpdate = millis();
    updateOLEDDisplay();
  }
  

  
  // Send data to Firebase periodically (only if connected to WiFi)
  if (wifiConnected && millis() - lastFirebaseUpdate >= FIREBASE_UPDATE_INTERVAL) {
    lastFirebaseUpdate = millis();
    sendDataToFirebase();
  }
  
  // Send heartbeat to Firebase (keep device status as "online")
  if (wifiConnected && millis() - lastHeartbeat >= HEARTBEAT_INTERVAL) {
    lastHeartbeat = millis();
    sendHeartbeat();
  }
}

// ==================== WIFI FUNCTIONS ====================

void connectToWiFi(String ssid, String password) {
  WiFi.mode(WIFI_STA);
  WiFi.disconnect();
  delay(100);

  // ADD THIS:
  displayConnecting();

  // ADD THIS:
  WiFi.begin(ssid.c_str(), password.c_str());
  
  Serial.print("Connecting to " + ssid);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    wifiConnected = true;
    Serial.println("\n\n✓ WiFi Connected Successfully!");

    // ADD THIS:
    displayWiFiConnected();
    delay(3000);


    Serial.println("  SSID: " + WiFi.SSID());
    Serial.println("  IP Address: " + WiFi.localIP().toString());
    Serial.println("  Signal Strength: " + String(WiFi.RSSI()) + " dBm");
    Serial.println("  MAC Address: " + WiFi.macAddress());
    
    // Setup web server for device monitoring
    setupWebServer();
    
    // Register device to Firebase database
    registerDeviceToFirebase();
    
  } else {
    wifiConnected = false;
    Serial.println("\n\n❌ WiFi Connection Failed!");
    Serial.println("  Please check your credentials and try again.");
  }
}

void startAPMode() {
  Serial.println("\n========================================");
  Serial.println("   ACCESS POINT MODE ACTIVATED");
  Serial.println("========================================");
  
  String apSSID = String(AP_SSID_PREFIX) + deviceId.substring(3, 9);
  
  WiFi.mode(WIFI_AP);
  WiFi.softAP(apSSID.c_str(), AP_PASSWORD);
  
  IPAddress apIP = WiFi.softAPIP();
  
  Serial.println("\nAP Configuration:");
  Serial.println("  SSID: " + apSSID);
  Serial.println("  Password: " + String(AP_PASSWORD));
  Serial.println("  IP Address: " + apIP.toString());
  Serial.println("\n📱 SETUP INSTRUCTIONS:");
  Serial.println("  1. Connect your phone to the WiFi network above");
  Serial.println("  2. Open a browser (captive portal will auto-open)");
  Serial.println("  3. Enter your home WiFi credentials");
  Serial.println("  4. Device will restart and connect");
  Serial.println("========================================\n");


  
  // Start DNS server for captive portal
  dnsServer.start(53, "*", apIP);
  
  // Setup configuration web server
  setupConfigServer();

    // ADD THIS at the very end:
  displayAPMode();
}

// ==================== WEB SERVER (AP MODE - CONFIGURATION) ====================

void setupConfigServer() {
  // Redirect all requests to config page (captive portal behavior)
  server.onNotFound([]() {
    server.sendHeader("Location", "/", true);
    server.send(302, "text/plain", "");
  });
  
  server.on("/", HTTP_GET, handleConfigPage);
  server.on("/configure", HTTP_POST, handleConfigure);
  server.on("/scan", HTTP_GET, handleWiFiScan);
  
  server.begin();
  Serial.println("✓ Configuration server started on " + WiFi.softAPIP().toString());
}

void handleConfigPage() {
  String html = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Gas Detector Setup</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; 
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
      min-height: 100vh; 
      padding: 20px; 
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .container { 
      max-width: 450px; 
      width: 100%;
      background: white; 
      border-radius: 20px; 
      box-shadow: 0 20px 60px rgba(0,0,0,0.3); 
      overflow: hidden; 
    }
    .header { 
      background: linear-gradient(135deg, #2196F3, #1976D2); 
      color: white; 
      padding: 35px 25px; 
      text-align: center; 
    }
    .header h1 { 
      font-size: 26px; 
      margin-bottom: 10px; 
      font-weight: 600;
    }
    .header p { 
      opacity: 0.95; 
      font-size: 15px; 
      margin-bottom: 8px;
    }
    .sensor-badge { 
      background: rgba(255,255,255,0.25); 
      padding: 8px 18px; 
      border-radius: 25px; 
      display: inline-block; 
      margin-top: 15px; 
      font-size: 13px; 
      font-weight: 500;
    }
    .device-id { 
      background: rgba(255,255,255,0.15); 
      padding: 14px; 
      border-radius: 10px; 
      margin-top: 18px; 
      font-family: 'Courier New', monospace; 
      font-size: 14px; 
      letter-spacing: 1.5px; 
      font-weight: 600;
    }
    .content { 
      padding: 35px 25px; 
    }
    .form-group { 
      margin-bottom: 22px; 
    }
    .form-group label { 
      display: block; 
      margin-bottom: 10px; 
      font-weight: 600; 
      color: #333; 
      font-size: 15px; 
    }
    .form-group input { 
      width: 100%; 
      padding: 16px; 
      border: 2px solid #e0e0e0; 
      border-radius: 10px; 
      font-size: 15px; 
      transition: all 0.3s; 
      font-family: inherit;
    }
    .form-group input:focus { 
      outline: none; 
      border-color: #2196F3; 
      box-shadow: 0 0 0 3px rgba(33,150,243,0.1);
    }
    .btn { 
      width: 100%; 
      padding: 18px; 
      background: linear-gradient(135deg, #2196F3, #1976D2); 
      color: white; 
      border: none; 
      border-radius: 10px; 
      font-size: 17px; 
      font-weight: 600; 
      cursor: pointer; 
      transition: all 0.3s;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .btn:hover { 
      transform: translateY(-2px); 
      box-shadow: 0 10px 25px rgba(33,150,243,0.4); 
    }
    .btn:active { 
      transform: translateY(0); 
    }
    .info { 
      background: #f8f9fa; 
      padding: 18px; 
      border-radius: 10px; 
      margin-top: 25px; 
      font-size: 14px; 
      color: #555; 
      line-height: 1.6;
      border-left: 4px solid #2196F3;
    }
    .info strong { 
      color: #333; 
      display: block;
      margin-bottom: 8px;
      font-size: 15px;
    }
    .info ol {
      margin-left: 20px;
      margin-top: 8px;
    }
    .info li {
      margin-bottom: 5px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔧 Gas Detector Setup</h1>
      <p>Configure WiFi Connection</p>
      <div class="sensor-badge">MQ-6 Sensor (LPG/Propane/Butane)</div>
      <div class="device-id">)rawliteral" + deviceId + R"rawliteral(</div>
    </div>
    <div class="content">
      <form action="/configure" method="POST">
        <div class="form-group">
          <label>WiFi Network Name (SSID)</label>
          <input type="text" name="ssid" placeholder="Enter your WiFi network name" required autofocus>
        </div>
        <div class="form-group">
          <label>WiFi Password</label>
          <input type="password" name="password" placeholder="Enter WiFi password" required>
        </div>
        <button type="submit" class="btn">Connect to WiFi</button>
      </form>
      <div class="info">
        <strong>📋 Next Steps:</strong>
        <ol>
          <li>Enter your home WiFi credentials above</li>
          <li>Click "Connect to WiFi"</li>
          <li>Device will restart and connect</li>
          <li>Open the mobile app to pair this device</li>
        </ol>
      </div>
    </div>
  </div>
</body>
</html>
)rawliteral";
  
  server.send(200, "text/html", html);
}

void handleConfigure() {
  String ssid = server.arg("ssid");
  String password = server.arg("password");
  
  if (ssid.length() == 0) {
    server.send(400, "text/plain", "Error: SSID is required");
    return;
  }
  
  // Save WiFi credentials to flash memory
  preferences.begin("wifi-config", false);
  preferences.putString("ssid", ssid);
  preferences.putString("password", password);
  preferences.putBool("configured", true);
  preferences.end();
  
  String html = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Configuration Saved</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; 
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
      min-height: 100vh; 
      display: flex; 
      align-items: center; 
      justify-content: center; 
      padding: 20px; 
    }
    .container { 
      max-width: 450px; 
      background: white; 
      border-radius: 20px; 
      box-shadow: 0 20px 60px rgba(0,0,0,0.3); 
      padding: 45px 35px; 
      text-align: center; 
    }
    .icon { 
      font-size: 72px; 
      margin-bottom: 25px; 
      animation: checkmark 0.8s ease-in-out;
    }
    @keyframes checkmark {
      0% { transform: scale(0); }
      50% { transform: scale(1.2); }
      100% { transform: scale(1); }
    }
    h1 { 
      color: #4CAF50; 
      font-size: 28px; 
      margin-bottom: 15px; 
      font-weight: 600;
    }
    p { 
      color: #666; 
      line-height: 1.7; 
      margin-bottom: 15px; 
      font-size: 16px;
    }
    .highlight { 
      background: #f5f5f5; 
      padding: 15px; 
      border-radius: 10px; 
      margin: 25px 0; 
      font-family: monospace; 
      font-size: 15px; 
      color: #333;
      font-weight: 600;
    }
    .steps {
      text-align: left;
      background: #e3f2fd;
      padding: 20px;
      border-radius: 10px;
      margin-top: 20px;
    }
    .steps strong {
      color: #1976D2;
      font-size: 16px;
    }
    .steps ol {
      margin-top: 12px;
      margin-left: 20px;
      color: #555;
    }
    .steps li {
      margin-bottom: 8px;
      line-height: 1.5;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">✓</div>
    <h1>Configuration Saved!</h1>
    <p>Your gas detector is now connecting to WiFi...</p>
    <div class="highlight">Network: )rawliteral" + ssid + R"rawliteral(</div>
    <div class="steps">
      <strong>📱 What's Next:</strong>
      <ol>
        <li>Close this page</li>
        <li>Reconnect your phone to your home WiFi</li>
        <li>Wait 10 seconds for device to connect</li>
        <li>Open the Gas Detector app</li>
        <li>Tap "Add Device" to pair this detector</li>
      </ol>
    </div>
  </div>
</body>
</html>
)rawliteral";
  
  server.send(200, "text/html", html);
  
  Serial.println("\n✓ Configuration saved successfully!");
  Serial.println("  SSID: " + ssid);
  Serial.println("  Restarting device in 3 seconds...\n");
  
  delay(3000);
  ESP.restart();
}

void handleWiFiScan() {
  // Optional: WiFi network scanner
  String json = "{\"networks\":[]}";
  server.send(200, "application/json", json);
}

// ==================== WEB SERVER (STATION MODE - MONITORING) ====================

void setupWebServer() {
  server.on("/", HTTP_GET, handleStatusPage);
  server.on("/api/status", HTTP_GET, handleAPIStatus);
  server.on("/api/device", HTTP_GET, handleDeviceInfo);
  
  server.begin();
  Serial.println("✓ Device monitoring server started");
  Serial.println("  Access at: http://" + WiFi.localIP().toString());
}

void handleStatusPage() {
  String statusColor;
  String statusEmoji;
  
  if (currentStatus == "safe") {
    statusColor = "#4CAF50";
    statusEmoji = "✓";
  } else if (currentStatus == "warning") {
    statusColor = "#2196F3";
    statusEmoji = "⚠";
  } else if (currentStatus == "danger") {
    statusColor = "#FF9800";
    statusEmoji = "⚠";
  } else {
    statusColor = "#F44336";
    statusEmoji = "🚨";
  }
  
  String html = R"rawliteral(
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="refresh" content="3">
  <title>)rawliteral" + deviceName + R"rawliteral( - Status</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif; 
      background: #f5f5f5; 
      padding: 20px; 
    }
    .container { 
      max-width: 600px; 
      margin: 0 auto; 
    }
    .header { 
      background: white; 
      padding: 25px; 
      border-radius: 15px; 
      margin-bottom: 20px; 
      box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
    }
    .header h1 { 
      font-size: 26px; 
      color: #333; 
      margin-bottom: 8px; 
    }
    .header p { 
      color: #666; 
      font-size: 15px; 
    }
    .sensor-badge { 
      background: #e3f2fd; 
      color: #1976D2; 
      padding: 6px 14px; 
      border-radius: 15px; 
      font-size: 13px; 
      display: inline-block; 
      margin-top: 10px; 
      font-weight: 600;
    }
    .status-card { 
      background: )rawliteral" + statusColor + R"rawliteral(; 
      color: white; 
      padding: 40px 30px; 
      border-radius: 15px; 
      text-align: center; 
      margin-bottom: 20px; 
      box-shadow: 0 4px 15px rgba(0,0,0,0.2); 
    }
    .status-card .emoji {
      font-size: 48px;
      margin-bottom: 15px;
    }
    .status-card h2 { 
      font-size: 36px; 
      text-transform: uppercase; 
      letter-spacing: 3px; 
      margin-bottom: 10px;
      font-weight: 700;
    }
    .status-card p { 
      font-size: 20px; 
      opacity: 0.95; 
    }
    .data-grid { 
      background: white; 
      padding: 25px; 
      border-radius: 15px; 
      box-shadow: 0 2px 10px rgba(0,0,0,0.1); 
    }
    .data-row { 
      display: flex; 
      justify-content: space-between; 
      padding: 14px 0; 
      border-bottom: 1px solid #f0f0f0; 
    }
    .data-row:last-child { 
      border-bottom: none; 
    }
    .data-label { 
      color: #666; 
      font-size: 15px; 
      font-weight: 500;
    }
    .data-value { 
      color: #333; 
      font-weight: 600; 
      font-size: 15px; 
      font-family: monospace;
    }
    .refresh-note {
      text-align: center;
      color: #999;
      font-size: 13px;
      margin-top: 20px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>)rawliteral" + deviceName + R"rawliteral(</h1>
      <p>Real-time Gas Monitoring Dashboard</p>
      <span class="sensor-badge">MQ-6 Sensor</span>
    </div>
    
    <div class="status-card">
      <div class="emoji">)rawliteral" + statusEmoji + R"rawliteral(</div>
      <h2>)rawliteral" + currentStatus + R"rawliteral(</h2>
      <p>Gas Level: )rawliteral" + String(gasLevel) + R"rawliteral( PPM</p>
    </div>
    
    <div class="data-grid">
      <div class="data-row">
        <span class="data-label">Device ID</span>
        <span class="data-value">)rawliteral" + deviceId + R"rawliteral(</span>
      </div>
      <div class="data-row">
        <span class="data-label">Sensor Type</span>
        <span class="data-value">MQ-6 (LPG/Propane)</span>
      </div>
      <div class="data-row">
        <span class="data-label">Gas Level (PPM)</span>
        <span class="data-value">)rawliteral" + String(gasLevel) + R"rawliteral(</span>
      </div>
      <div class="data-row">
        <span class="data-label">Raw ADC Value</span>
        <span class="data-value">)rawliteral" + String(rawAnalogValue) + R"rawliteral(</span>
      </div>
      <div class="data-row">
        <span class="data-label">Status Code</span>
        <span class="data-value">)rawliteral" + String(statusCode) + R"rawliteral(</span>
      </div>
      <div class="data-row">
        <span class="data-label">WiFi Network</span>
        <span class="data-value">)rawliteral" + WiFi.SSID() + R"rawliteral(</span>
      </div>
      <div class="data-row">
        <span class="data-label">IP Address</span>
        <span class="data-value">)rawliteral" + WiFi.localIP().toString() + R"rawliteral(</span>
      </div>
      <div class="data-row">
        <span class="data-label">Signal Strength</span>
        <span class="data-value">)rawliteral" + String(WiFi.RSSI()) + R"rawliteral( dBm</span>
      </div>
      <div class="data-row">
        <span class="data-label">Uptime</span>
        <span class="data-value">)rawliteral" + String(millis()/1000) + R"rawliteral( sec</span>
      </div>
    </div>
    
    <div class="refresh-note">
      ⟳ Page auto-refreshes every 3 seconds
    </div>
  </div>
</body>
</html>
)rawliteral";
  
  server.send(200, "text/html", html);
}

void handleAPIStatus() {
  DynamicJsonDocument doc(768);
  
  doc["deviceId"] = deviceId;
  doc["deviceName"] = deviceName;
  doc["sensorType"] = "MQ-6";
  doc["status"] = currentStatus;
  doc["statusCode"] = statusCode;
  doc["gasLevel"] = gasLevel;
  doc["rawValue"] = rawAnalogValue;
  doc["alarmActive"] = alarmActive;
  
  JsonObject wifi = doc.createNestedObject("wifi");
  wifi["ssid"] = WiFi.SSID();
  wifi["rssi"] = WiFi.RSSI();
  wifi["ip"] = WiFi.localIP().toString();
  wifi["mac"] = WiFi.macAddress();
  
  doc["uptime"] = millis() / 1000;
  doc["freeHeap"] = ESP.getFreeHeap();
  
  String json;
  serializeJson(doc, json);
  
  server.send(200, "application/json", json);
}

void handleDeviceInfo() {
  DynamicJsonDocument doc(384);
  
  doc["deviceId"] = deviceId;
  doc["deviceName"] = deviceName;
  doc["sensorType"] = "MQ-6";
  doc["ipAddress"] = WiFi.localIP().toString();
  doc["configured"] = isConfigured;
  doc["connected"] = wifiConnected;
  doc["firmwareVersion"] = "1.0.0";
  
  String json;
  serializeJson(doc, json);
  
  server.send(200, "application/json", json);
}

// ==================== SENSOR FUNCTIONS ====================

void readSensor() {
  // Read analog value from MQ-6 sensor (0-4095 for ESP32 12-bit ADC)
  rawAnalogValue = analogRead(MQ6_PIN);
  
  // Convert to PPM (Parts Per Million)
  // MQ-6 detection range: 200-10000 PPM for LPG
  // This is a basic linear mapping - calibrate based on your sensor
  gasLevel = map(rawAnalogValue, 0, 4095, 0, 10000);
  gasLevel = constrain(gasLevel, 0, 10000);
  
  // Store previous status for change detection
  previousStatus = currentStatus;
  
  // Determine status based on configured thresholds
  if (gasLevel < THRESHOLD_SAFE) {
    currentStatus = "safe";
    statusCode = 0;
  } else if (gasLevel < THRESHOLD_WARNING) {
    currentStatus = "safe";
    statusCode = 1;
  } else if (gasLevel < THRESHOLD_DANGER) {
    currentStatus = "warning";
    statusCode = 2;
  } else if (gasLevel < THRESHOLD_CRITICAL) {
    currentStatus = "danger";
    statusCode = 3;
  } else {
    currentStatus = "critical";
    statusCode = 4;
  }
  
  // Log sensor reading to serial monitor
  Serial.print("Gas: " + String(gasLevel) + " PPM");
  Serial.print(" | Raw: " + String(rawAnalogValue));
  Serial.print(" | Status: " + currentStatus);
  
  // Alert if status changed
  if (previousStatus != currentStatus) {
    Serial.print(" ⚠ STATUS CHANGED! (" + previousStatus + " → " + currentStatus + ")");
  }
  
  Serial.println();
}

void updateStatusLED() {
  // LED indication patterns based on gas level status
  if (currentStatus == "safe") {
    // Safe: LED off
    digitalWrite(LED_PIN, LOW);
    
  } else if (currentStatus == "warning") {
    // Warning: Slow blink (1 Hz)
    digitalWrite(LED_PIN, (millis() / 1000) % 2 == 0 ? HIGH : LOW);
    
  } else if (currentStatus == "danger") {
    // Danger: Fast blink (2 Hz)
    digitalWrite(LED_PIN, (millis() / 500) % 2 == 0 ? HIGH : LOW);
    
  } else if (currentStatus == "critical") {
    // Critical: Very fast blink (4 Hz)
    digitalWrite(LED_PIN, (millis() / 250) % 2 == 0 ? HIGH : LOW);
  }
}

void handleAlarm() {
  // Activate alarm for DANGER and CRITICAL levels
  if (currentStatus == "danger" || currentStatus == "critical") {
    
    if (!alarmActive) {
      alarmActive = true;
      Serial.println("\n🚨 ALARM ACTIVATED! Gas levels dangerous!");
    }
    
    // Buzzer beeping pattern
    // CRITICAL: Faster beeping (200ms interval)
    // DANGER: Slower beeping (500ms interval)
    unsigned long beepInterval = (currentStatus == "critical") ? 200 : 500;
    
    if (millis() - lastBuzzerToggle >= beepInterval) {
      lastBuzzerToggle = millis();
      buzzerState = !buzzerState;
      digitalWrite(BUZZER_PIN, buzzerState ? HIGH : LOW);
    }
    
    // Activate relay (can be used for exhaust fan, ventilation, etc.)
    digitalWrite(RELAY_PIN, HIGH);
    
  } else {
    // Safe or Warning levels - deactivate alarm
    if (alarmActive) {
      alarmActive = false;
      Serial.println("\n✓ Alarm deactivated - gas levels safe");
    }
    
    // Turn off buzzer and relay
    digitalWrite(BUZZER_PIN, LOW);
    digitalWrite(RELAY_PIN, LOW);
    buzzerState = false;
  }
}

// ==================== FIREBASE FUNCTIONS ====================

void registerDeviceToFirebase() {
  if (!wifiConnected) {
    Serial.println("❌ Cannot register - WiFi not connected");
    return;
  }
  
  Serial.println("\n--- Registering Device to Firebase ---");
  
  String url = String(firebaseFunctionUrl) + "/registerDevice";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(10000);
  
  DynamicJsonDocument doc(512);
  doc["deviceId"] = deviceId;
  doc["ipAddress"] = WiFi.localIP().toString();
  
  JsonObject wifi = doc.createNestedObject("wifi");
  wifi["ssid"] = WiFi.SSID();
  wifi["rssi"] = WiFi.RSSI();
  
  String json;
  serializeJson(doc, json);
  
  Serial.println("Sending registration: " + json);
  
  int httpCode = http.POST(json);
  
  if (httpCode == 200) {
    String response = http.getString();
    Serial.println("✓ Registration successful!");
    Serial.println("Response: " + response);
    
    // Parse response
    DynamicJsonDocument resDoc(256);
    DeserializationError error = deserializeJson(resDoc, response);
    
    if (!error) {
      bool claimed = resDoc["claimed"] | false;
      
      if (claimed) {
        Serial.println("✓ Device is already paired to a user account");
      } else {
        Serial.println("⏳ Device registered - waiting for user to pair in the app");
      }
    }
  } else {
    Serial.println("❌ Registration failed!");
    Serial.println("HTTP Code: " + String(httpCode));
    if (httpCode > 0) {
      Serial.println("Response: " + http.getString());
    } else {
      Serial.println("Error: " + http.errorToString(httpCode));
    }
  }
  
  http.end();
}

void sendDataToFirebase() {
  if (!wifiConnected) return;
  
//   String url = String(firebaseFunctionUrl) + "/updateSensorData";

// NEW LINE: Use the specific URL provided by your deployment output
  String url = "https://updatesensordata-opaew23tkq-uc.a.run.app";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(5000);
  
  DynamicJsonDocument doc(384);
  doc["deviceId"] = deviceId;
  doc["authToken"] = authToken.length() > 0 ? authToken : "temp_token";
  doc["lpg"] = gasLevel;          // MQ-6 detects LPG
  doc["lpgRaw"] = rawAnalogValue;
  doc["co"] = 0;                  // MQ-6 doesn't detect CO (use MQ-7 for CO detection)
  doc["coRaw"] = 0;
  
  String json;
  serializeJson(doc, json);
  
  int httpCode = http.POST(json);
  
  if (httpCode == 200) {
    Serial.println("✓ Data sent to Firebase successfully");
  } else if (httpCode > 0) {
    Serial.println("❌ Firebase update failed - HTTP " + String(httpCode));
  } else {
    Serial.println("❌ Firebase connection error: " + http.errorToString(httpCode));
  }
  
  http.end();
}

void sendHeartbeat() {
  if (!wifiConnected) return;
  
  String url = String(firebaseFunctionUrl) + "/deviceHeartbeat";
  
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(5000);
  
  DynamicJsonDocument doc(128);
  doc["deviceId"] = deviceId;
  doc["status"] = "online";
  
  String json;
  serializeJson(doc, json);
  
  int httpCode = http.POST(json);
  
  if (httpCode == 200) {
    Serial.println("♥ Heartbeat sent");
  }
  
  http.end();
}

// Show startup screen
void displayStartupScreen() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("Gas Detector");
  display.println("v1.0 - MQ-6");
  display.println("");
  display.println("Initializing...");
  display.display();
  delay(2000);
}

// Update OLED Display with current status
void updateOLEDDisplay() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  
  // Line 1: Title
  display.setCursor(0, 0);
  display.println("GAS DETECTOR");
  display.drawLine(0, 10, 128, 10, SSD1306_WHITE);
  
  // Line 2: Device ID (first 10 chars)
  display.setCursor(0, 14);
  display.print("ID: ");
  String shortId = deviceId.substring(0, min(10, (int)deviceId.length()));
  display.println(shortId);
  
  // Line 3: Gas Level - LARGE
  display.setTextSize(2);
  display.setCursor(0, 26);
  display.print(gasLevel);
  display.setTextSize(1);
  display.println(" PPM");
  
  // Line 4: Status
  display.setTextSize(1);
  display.setCursor(0, 45);
  display.print("Status: ");

  // FIX: Create uppercase copy
  String statusUpper = currentStatus;
  statusUpper.toUpperCase();
  display.println(statusUpper);

  // Line 5: WiFi Status
  display.setCursor(0, 56);
  if (wifiConnected) {
    display.print("WiFi: OK");
  } else {
    display.print("WiFi: AP Mode");
  }
  
  display.display();
}

// Show Device ID prominently (call this after generating deviceId in setup)
void displayDeviceID() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  
  display.setCursor(0, 0);
  display.println("DEVICE ID:");
  display.drawLine(0, 10, 128, 10, SSD1306_WHITE);
  
  display.setCursor(0, 15);
  display.setTextSize(1);
  
  // Split Device ID into lines if needed
  int lineLength = 16;
  for (int i = 0; i < deviceId.length(); i += lineLength) {
    String line = deviceId.substring(i, min(i + lineLength, (int)deviceId.length()));
    display.println(line);
  }
  
  display.setCursor(0, 50);
  display.println("Write this down!");
  
  display.display();
}

// Show connecting WiFi screen
void displayConnecting() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0, 10);
  display.println("Connecting WiFi");
  display.setCursor(0, 30);
  display.setTextSize(1);
  display.println(savedSSID);
  display.display();
}

// Show WiFi connected screen
void displayWiFiConnected() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0, 10);
  display.println("WiFi Connected!");
  display.setCursor(0, 25);
  display.println(WiFi.SSID());
  display.setCursor(0, 40);
  display.print("IP: ");
  display.println(WiFi.localIP().toString());
  display.display();
}

// Show AP mode screen
void displayAPMode() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setCursor(0, 0);
  display.println("AP MODE");
  display.drawLine(0, 10, 128, 10, SSD1306_WHITE);
  
  display.setCursor(0, 15);
  String apSSID = String(AP_SSID_PREFIX) + deviceId.substring(3, 9);
  if (apSSID.length() > 16) {
    display.println(apSSID.substring(0, 16));
    display.println(apSSID.substring(16));
  } else {
    display.println(apSSID);
  }
  
  display.setCursor(0, 40);
  display.print("Pass: ");
  display.println(AP_PASSWORD);
  
  display.setCursor(0, 55);
  display.println("Connect to setup");
  
  display.display();
}


// ==================== END OF CODE ====================