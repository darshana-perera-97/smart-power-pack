/*
 * Configuration file for NodeMCU Firebase Switch Controller
 * Copy this file and rename to config.h, then update with your settings
 */

#ifndef CONFIG_H
#define CONFIG_H

// WiFi Configuration
const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Firebase Configuration
#define FIREBASE_HOST "smart-multi-meter-default-rtdb.firebaseio.com"
#define FIREBASE_AUTH ""  // Leave empty for public access, or add your auth token

// Hardware Pin Configuration
#define RELAY_PIN D1      // GPIO5 - Relay control pin
#define LED_PIN D2        // GPIO4 - Status LED
#define STATUS_LED D4     // Built-in LED on NodeMCU

// Timing Configuration
const unsigned long CHECK_INTERVAL = 1000;  // Check Firebase every 1 second
const unsigned long BLINK_INTERVAL = 500;   // Blink status LED every 500ms

// Debug Configuration
#define SERIAL_BAUD 115200
#define DEBUG_MODE true   // Set to false to reduce serial output

#endif
