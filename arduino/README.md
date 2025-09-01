# NodeMCU Firebase Switch Controller

This Arduino code allows a NodeMCU ESP8266 to read switch state from Firebase Realtime Database and control a relay/LED accordingly.

## Features

- ✅ Reads switch state from Firebase Realtime Database every 1 second
- ✅ Controls relay and LED based on Firebase data
- ✅ Visual feedback with status LEDs
- ✅ Error handling and reconnection
- ✅ Serial monitoring for debugging
- ✅ WiFi connection management

## Hardware Requirements

- NodeMCU ESP8266 development board
- Relay module (5V or 3.3V compatible)
- LED and resistor (optional, for visual feedback)
- Jumper wires
- Breadboard (optional)

## Pin Connections

| Component | NodeMCU Pin | GPIO | Description |
|-----------|-------------|------|-------------|
| Relay Module | D1 | GPIO5 | Relay control signal |
| Status LED | D2 | GPIO4 | Visual feedback LED |
| Built-in LED | D4 | GPIO2 | System status indicator |

## Software Requirements

### Arduino IDE Libraries

Install the following libraries through Arduino IDE Library Manager:

1. **ESP8266WiFi** (usually included with ESP8266 board package)
2. **FirebaseESP8266** by Mobizt
3. **ArduinoJson** by Benoit Blanchon

### Board Configuration

1. Install ESP8266 board package in Arduino IDE
2. Select board: "NodeMCU 1.0 (ESP-12E Module)"
3. Set upload speed to 115200

## Setup Instructions

### 1. Configure WiFi Credentials

Edit the following lines in the code:

```cpp
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
```

### 2. Firebase Configuration

The code is configured to connect to:
- **Firebase Host**: `smart-multi-meter-default-rtdb.firebaseio.com`
- **Data Path**: `/switch-1`

If you need authentication, uncomment and set:
```cpp
#define FIREBASE_AUTH "YOUR_FIREBASE_AUTH_TOKEN"
```

### 3. Upload Code

1. Connect NodeMCU to computer via USB
2. Select correct COM port in Arduino IDE
3. Upload the code to NodeMCU

## Usage

### Serial Monitor

Open Serial Monitor (115200 baud) to see:
- WiFi connection status
- Firebase connection status
- Switch state changes
- Error messages
- System status

### Expected Output

```
NodeMCU Firebase Switch Controller
==================================
Connecting to WiFi: YourWiFiName
.....
WiFi connected!
IP address: 192.168.1.100
Signal strength: -45 dBm

Setup complete!
Monitoring Firebase for switch state changes...

Switch state changed: ON
Hardware: Relay ON, LED ON
```

### Testing

1. **Manual Testing**: Use the mobile app or web interface to toggle the switch
2. **Serial Commands**: You can add serial commands for testing (see code comments)
3. **Hardware Verification**: Check that relay and LED respond to Firebase changes

## Firebase Data Structure

The code reads from this Firebase path:
```
https://smart-multi-meter-default-rtdb.firebaseio.com/switch-1
```

Expected data format:
```json
{
  "switch-1": true  // or false
}
```

## Troubleshooting

### Common Issues

1. **WiFi Connection Failed**
   - Check SSID and password
   - Ensure WiFi network is 2.4GHz (ESP8266 doesn't support 5GHz)
   - Check signal strength

2. **Firebase Connection Failed**
   - Verify Firebase URL is correct
   - Check internet connection
   - Verify Firebase project is active

3. **Relay Not Responding**
   - Check wiring connections
   - Verify relay module power supply
   - Test relay with multimeter

4. **Code Upload Failed**
   - Check COM port selection
   - Try different USB cable
   - Press and hold FLASH button during upload

### Debug Information

The code provides extensive debug information:
- WiFi connection status
- Firebase read operations
- Hardware state changes
- Error messages with reasons

## Customization

### Change Check Interval

Modify the check interval (default: 1 second):
```cpp
const unsigned long checkInterval = 2000; // 2 seconds
```

### Add More Relays

To control multiple relays:
```cpp
#define RELAY2_PIN D3
#define RELAY3_PIN D5

// In setup()
pinMode(RELAY2_PIN, OUTPUT);
pinMode(RELAY3_PIN, OUTPUT);

// In updateHardware()
digitalWrite(RELAY2_PIN, state ? HIGH : LOW);
digitalWrite(RELAY3_PIN, state ? HIGH : LOW);
```

### Add Serial Commands

Add interactive commands for testing:
```cpp
void handleSerialCommands() {
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim();
    
    if (command == "status") {
      printStatus();
    } else if (command == "on") {
      setSwitchState(true);
    } else if (command == "off") {
      setSwitchState(false);
    }
  }
}
```

## Safety Notes

- ⚠️ **High Voltage Warning**: When using relays with mains voltage, ensure proper insulation and safety measures
- ⚠️ **Power Supply**: Use appropriate power supply for relay module
- ⚠️ **Grounding**: Ensure proper grounding for safety
- ⚠️ **Testing**: Always test with low voltage before connecting to mains

## License

This code is provided as-is for educational and development purposes. Use at your own risk.
