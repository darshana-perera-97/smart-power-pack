#include <ESP8266WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// WiFi Credentials
char ssid[] = "Xiomi";
char pass[] = "dddddddd";

// Firebase Credentials
#define API_KEY "AIzaSyD6KZW922Gkdios-p6M-tX3ajxLUhhi_dM"
#define DATABASE_URL "https://smart-multi-meter-default-rtdb.firebaseio.com/"

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
bool signupOK = false;

void setup()
{
  Serial.begin(115200);
  WiFi.begin(ssid, pass);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED)
  {
    Serial.print(".");
    delay(300);
  }
  Serial.println("\nWiFi connected.");

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;

  // Anonymous sign-up
  if (Firebase.signUp(&config, &auth, "", ""))
  {
    Serial.println("Firebase signed up (anonymous)");
    signupOK = true;
  }
  else
  {
    Serial.printf("Sign-up failed: %s\n", config.signer.signupError.message.c_str());
  }

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop()
{
  if (signupOK && Firebase.ready())
  {
    // Read root ("/") JSON data from Firebase RTDB
    if (Firebase.RTDB.getJSON(&fbdo, "/switch-1"))
    {
      String jsonData = fbdo.jsonString();
      Serial.println("Firebase JSON Data:");
      Serial.println(jsonData);
    }
    else
    {
      Serial.printf("Failed to get data: %s\n", fbdo.errorReason().c_str());
    }
  }
  else
  {
    Serial.println("Firebase not ready or signup failed.");
  }
  delay(5000);
}
