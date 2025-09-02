#include <ESP8266WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// WiFi Credentials
char ssid[] = "Xiomi";
char pass[] = "dddddddd";

// Firebase Credentials
#define API_KEY      "AIzaSyD6KZW922Gkdios-p6M-tX3ajxLUhhi_dM"
#define DATABASE_URL "https://smart-multi-meter-default-rtdb.firebaseio.com/"

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
bool signupOK = false;

const int ledPin = 2;    // Built-in LED pin on ESP8266 (GPIO2)
const int relayPin = 5;  // Relay control pin on ESP8266 (GPIO5, D1)

// Normally Open relay module: LOW = relay ON, HIGH = relay OFF

void setup() {
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, HIGH); // LED off initially (active LOW)
  pinMode(relayPin, OUTPUT);
  digitalWrite(relayPin, HIGH); // Relay off initially (Normally Open relay)

  WiFi.begin(ssid, pass);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println("\nWiFi connected.");

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;
  if (Firebase.signUp(&config, &auth, "", "")) {
    Serial.println("Firebase signed up (anonymous)");
    signupOK = true;
  } else {
    Serial.printf("Sign-up failed: %s\n", config.signer.signupError.message.c_str());
  }
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  if (signupOK && Firebase.ready()) {
    if (Firebase.RTDB.getJSON(&fbdo, "/")) {
      Serial.println("Firebase JSON Data:");
      Serial.println(fbdo.jsonString());

      FirebaseJsonData switchJsonData, timerJsonData, timerValJsonData;
      bool switchState = false;
      bool timerState = false;
      int timerVal = 0;

      // Get switch-1 state
      if (fbdo.jsonObjectPtr()->get(switchJsonData, "switch-1")) {
        switchState = switchJsonData.boolValue;
        Serial.printf("Switch-1 state: %s\n", switchState ? "ON" : "OFF");
      } else {
        Serial.println("Failed to get 'switch-1' from JSON");
      }

      // Get timer state
      if (fbdo.jsonObjectPtr()->get(timerJsonData, "timer")) {
        timerState = timerJsonData.boolValue;
        Serial.printf("Timer state: %s\n", timerState ? "true" : "false");
      } else {
        Serial.println("Failed to get 'timer' from JSON");
      }

      // Get timer-val value
      if (fbdo.jsonObjectPtr()->get(timerValJsonData, "timer-val")) {
        timerVal = timerValJsonData.intValue;
        Serial.printf("Timer-val: %d\n", timerVal);
      } else {
        Serial.println("Failed to get 'timer-val' from JSON");
      }

      // If timer is true, decrement timer-val every second
      if (timerState) {
        if (timerVal > 0) {
          timerVal--;
          Serial.printf("Decremented timer-val: %d\n", timerVal);
          if (timerVal < 1) {
            switchState = false;  // Turn off switch if timer-val < 1
            timerState = false;   // Stop timer
            Serial.println("timer-val < 1, turning switch-1 OFF and stopping timer.");
          }
          // Update timer-val in Firebase
          if (!Firebase.RTDB.setInt(&fbdo, "/timer-val", timerVal)) {
            Serial.printf("Failed to update timer-val: %s\n", fbdo.errorReason().c_str());
          }
          // Update switch-1 if changed
          if (!Firebase.RTDB.setBool(&fbdo, "/switch-1", switchState)) {
            Serial.printf("Failed to update switch-1: %s\n", fbdo.errorReason().c_str());
          }
          // Update timer state if changed
          if (!Firebase.RTDB.setBool(&fbdo, "/timer", timerState)) {
            Serial.printf("Failed to update timer: %s\n", fbdo.errorReason().c_str());
          }
        }
      }

      // Reflect switch and relay status locally
      digitalWrite(ledPin, switchState ? LOW : HIGH);     // LED on if true
      digitalWrite(relayPin, switchState ? LOW : HIGH);   // Relay on if true

    } else {
      Serial.printf("Failed to get data: %s\n", fbdo.errorReason().c_str());
    }
  } else {
    Serial.println("Firebase not ready or signup failed.");
  }
  delay(1000);
}
