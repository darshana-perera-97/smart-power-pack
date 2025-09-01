/*
 * NodeMCU Firebase Switch Controller
 * Reads switch state from Firebase Realtime Database
 * Controls a relay/LED based on the switch state
 * 
 * Firebase URL: https://smart-multi-meter-default-rtdb.firebaseio.com/switch-1
 * 
 * Hardware:
 * - NodeMCU ESP8266
 * - Relay module connected to D1 (GPIO5)
 * - LED connected to D2 (GPIO4) for visual feedback
 * 
 * Libraries required:
 * - ESP8266WiFi
 * - FirebaseESP8266
 * - ArduinoJson
 */

#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>
#include <ArduinoJson.h>

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// Firebase configuration
#define FIREBASE_HOST "smart-multi-meter-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH "YOUR_FIREBASE_AUTH_TOKEN" // Optional, can be left empty for public access

// Pin definitions
#define RELAY_PIN D1    // GPIO5 - Relay control pin
#define LED_PIN D2      // GPIO4 - Status LED
#define STATUS_LED D4   // Built-in LED on NodeMCU

// Firebase data object
FirebaseData firebaseData;

// Variables
bool switchState = false;
bool lastSwitchState = false;
unsigned long lastCheckTime = 0;
const unsigned long checkInterval = 1000; // Check every 1 second

void setup() {
  Serial.begin(115200);
  Serial.println();
  Serial.println("NodeMCU Firebase Switch Controller");
  Serial.println("==================================");
  
  // Initialize pins
  pinMode(RELAY_PIN, OUTPUT);
  pinMode(LED_PIN, OUTPUT);
  pinMode(STATUS_LED, OUTPUT);
  
  // Turn off relay and LEDs initially
  digitalWrite(RELAY_PIN, LOW);
  digitalWrite(LED_PIN, LOW);
  digitalWrite(STATUS_LED, LOW);
  
  // Connect to WiFi
  connectToWiFi();
  
  // Initialize Firebase
  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  Firebase.reconnectWiFi(true);
  
  // Set timeout for Firebase operations
  Firebase.setReadTimeout(firebaseData, 1000 * 60);
  Firebase.setwriteSizeLimit(firebaseData, "tiny");
  
  Serial.println("Setup complete!");
  Serial.println("Monitoring Firebase for switch state changes...");
  Serial.println();
}

void loop() {
  // Check Firebase every second
  if (millis() - lastCheckTime >= checkInterval) {
    checkFirebaseSwitch();
    lastCheckTime = millis();
  }
  
  // Blink status LED to show activity
  static unsigned long lastBlink = 0;
  if (millis() - lastBlink >= 500) {
    digitalWrite(STATUS_LED, !digitalRead(STATUS_LED));
    lastBlink = millis();
  }
  
  delay(10); // Small delay to prevent watchdog reset
}

void connectToWiFi() {
  Serial.print("Connecting to WiFi: ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println();
  Serial.println("WiFi connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
  Serial.print("Signal strength: ");
  Serial.print(WiFi.RSSI());
  Serial.println(" dBm");
  Serial.println();
}

void checkFirebaseSwitch() {
  // Read switch state from Firebase
  if (Firebase.getBool(firebaseData, "/switch-1")) {
    if (firebaseData.dataType() == "boolean") {
      switchState = firebaseData.boolData();
      
      // Check if state changed
      if (switchState != lastSwitchState) {
        Serial.print("Switch state changed: ");
        Serial.println(switchState ? "ON" : "OFF");
        
        // Update hardware
        updateHardware(switchState);
        
        lastSwitchState = switchState;
      }
    } else {
      Serial.println("Error: Expected boolean data type");
    }
  } else {
    Serial.println("Error reading from Firebase: " + firebaseData.errorReason());
    
    // Blink error pattern on status LED
    for (int i = 0; i < 3; i++) {
      digitalWrite(STATUS_LED, HIGH);
      delay(100);
      digitalWrite(STATUS_LED, LOW);
      delay(100);
    }
  }
}

void updateHardware(bool state) {
  if (state) {
    // Switch ON
    digitalWrite(RELAY_PIN, HIGH);  // Turn on relay
    digitalWrite(LED_PIN, HIGH);    // Turn on LED
    Serial.println("Hardware: Relay ON, LED ON");
  } else {
    // Switch OFF
    digitalWrite(RELAY_PIN, LOW);   // Turn off relay
    digitalWrite(LED_PIN, LOW);     // Turn off LED
    Serial.println("Hardware: Relay OFF, LED OFF");
  }
}

// Function to manually set switch state (for testing)
void setSwitchState(bool state) {
  if (Firebase.setBool(firebaseData, "/switch-1", state)) {
    Serial.println("Successfully set switch state to: " + String(state ? "ON" : "OFF"));
  } else {
    Serial.println("Error setting switch state: " + firebaseData.errorReason());
  }
}

// Function to get current switch state
bool getSwitchState() {
  if (Firebase.getBool(firebaseData, "/switch-1")) {
    if (firebaseData.dataType() == "boolean") {
      return firebaseData.boolData();
    }
  }
  return false;
}

// Function to print system status
void printStatus() {
  Serial.println("\n=== System Status ===");
  Serial.print("WiFi Status: ");
  Serial.println(WiFi.status() == WL_CONNECTED ? "Connected" : "Disconnected");
  Serial.print("WiFi Signal: ");
  Serial.print(WiFi.RSSI());
  Serial.println(" dBm");
  Serial.print("Switch State: ");
  Serial.println(switchState ? "ON" : "OFF");
  Serial.print("Relay State: ");
  Serial.println(digitalRead(RELAY_PIN) ? "ON" : "OFF");
  Serial.print("LED State: ");
  Serial.println(digitalRead(LED_PIN) ? "ON" : "OFF");
  Serial.print("Free Heap: ");
  Serial.print(ESP.getFreeHeap());
  Serial.println(" bytes");
  Serial.println("====================\n");
}
