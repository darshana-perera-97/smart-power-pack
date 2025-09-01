/*
 * Simple NodeMCU Firebase Switch Reader
 * Basic version for beginners
 * 
 * This code reads switch state from Firebase and controls an LED
 * Firebase URL: https://smart-multi-meter-default-rtdb.firebaseio.com/switch-1
 */

#include <ESP8266WiFi.h>
#include <FirebaseESP8266.h>

// WiFi settings - CHANGE THESE!
const char* ssid = "YOUR_WIFI_NAME";
const char* password = "YOUR_WIFI_PASSWORD";

// Firebase settings
#define FIREBASE_HOST "smart-multi-meter-default-rtdb.firebaseio.com"

// Pin for LED
#define LED_PIN D4  // Built-in LED on NodeMCU

// Firebase object
FirebaseData firebaseData;

void setup() {
  Serial.begin(115200);
  Serial.println("Starting NodeMCU Firebase Switch Reader...");
  
  // Setup LED pin
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  // Connect to WiFi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.println("WiFi connected!");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());
  
  // Initialize Firebase
  Firebase.begin(FIREBASE_HOST);
  Serial.println("Firebase connected!");
  Serial.println("Reading switch state every 2 seconds...");
}

void loop() {
  // Read switch state from Firebase
  if (Firebase.getBool(firebaseData, "/switch-1")) {
    bool switchState = firebaseData.boolData();
    
    // Control LED based on switch state
    if (switchState) {
      digitalWrite(LED_PIN, HIGH);  // Turn ON LED
      Serial.println("Switch: ON  -> LED: ON");
    } else {
      digitalWrite(LED_PIN, LOW);   // Turn OFF LED
      Serial.println("Switch: OFF -> LED: OFF");
    }
  } else {
    Serial.println("Error reading Firebase: " + firebaseData.errorReason());
  }
  
  delay(2000); // Wait 2 seconds before next check
}
