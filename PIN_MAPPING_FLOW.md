# Pin Mapping System - Complete User Flow

## Overview
The DeZer0 app implements a complete hardware pin mapping system that connects marketplace tools with physical hardware configuration. This ensures users can safely run tools without hardcoded GPIO pins.

---

## User Flow

### Step 1: Connect to Device
1. User opens the app
2. Goes to **Device** tab
3. Connects to ESP32 via WiFi
4. Views device details (model, firmware version, memory, etc.)

### Step 2: Configure Hardware
1. User goes to **Hardware Config** tab (4th bottom navigation item)
2. Adds hardware modules (e.g., LED, Button, Sensor)
3. For each module, assigns physical pins:
   - Example: LED module
     - GND → PIN 5 (Ground)
     - Signal → PIN 23 (GPIO23)
4. Saves configuration
5. Configuration is persisted locally and synced to device

### Step 3: Browse Marketplace
1. User goes to **Tools** tab
2. Browses available tools from marketplace
3. Views tool details showing:
   - Description
   - Version, size, category
   - **Hardware Requirements** (if tool needs pins)
   - Example: "LED Blink Tool requires: LED - Signal (output)"

### Step 4: Install Tool
1. User taps "Install" on a tool
2. Tool downloads and installs
3. Tool appears in installed tools list

### Step 5: Run Tool
1. User opens the installed tool
2. Taps "Run" button
3. **App performs pin check:**
   - If required pins are NOT configured:
     - Shows dialog: "Hardware Configuration Required"
     - Lists missing components
     - Provides "Configure Hardware" button
     - User is redirected to Hardware Config screen
   - If required pins ARE configured:
     - App builds pin mappings (e.g., `LED_PIN=23`)
     - Sends script to ESP32 with pin mappings
     - Script executes using configured pins
     - Console shows: "Using LED on GPIO23"

### Step 6: View Results
1. Console displays real-time execution logs
2. Activity history records the execution
3. User sees success/failure status

---

## Developer Guide: Creating Tools with Pin Requirements

### Tool Manifest (manifest.json)

```json
{
  "id": "led_blink_tool",
  "name": "LED Blink Tool",
  "author": "devkiraa",
  "version": "1.0.0",
  "description": "Blinks an LED at a specific interval",
  "category": "GPIO",
  "size": "2 KB",
  "script_filename": "led_blink.py",
  "changelog": "Initial release",
  "pin_requirements": [
    {
      "name": "LED",
      "function": "Signal",
      "mode": "output",
      "required": true,
      "description": "Status LED for blinking"
    }
  ]
}
```

### Pin Requirement Fields

- **name**: Component name (e.g., "LED", "BUTTON", "SENSOR")
- **function**: Pin function (e.g., "Signal", "SDA", "SCL", "TX", "RX")
- **mode**: Pin mode ("output", "input", "i2c", "spi", "uart")
- **required**: Boolean - is this pin mandatory?
- **description**: Human-readable description for users

### Tool Script (Python Example)

```python
# Pin mappings are automatically injected by the app
# Variable format: {NAME}_PIN where NAME is from manifest

led_pin = params.get('LED_PIN')  # Gets actual GPIO number

if led_pin is None:
    print("Error: LED_PIN not configured")
    raise SystemExit(1)

print(f"Using LED on GPIO{led_pin}")

# Use the pin in your code
gpio_config(led_pin, GPIO_OUTPUT)
gpio_set(led_pin, 1)  # Turn ON
sleep(1000)
gpio_set(led_pin, 0)  # Turn OFF
```

---

## Pin Mapping Variable Naming

The app creates variables in this format:
- Pattern: `{COMPONENT_NAME}_PIN`
- Example: LED → `LED_PIN`
- Example: BUTTON → `BUTTON_PIN`
- Example: SENSOR_DHT11 → `SENSOR_DHT11_PIN`

The component name is converted to uppercase and "_PIN" is appended.

---

## Multiple Pins Example

For components with multiple pins (e.g., I2C sensor):

```json
"pin_requirements": [
  {
    "name": "SENSOR",
    "function": "SDA",
    "mode": "i2c",
    "required": true,
    "description": "I2C Data Line"
  },
  {
    "name": "SENSOR",
    "function": "SCL",
    "mode": "i2c",
    "required": true,
    "description": "I2C Clock Line"
  }
]
```

Script receives:
```python
sensor_sda = params.get('SENSOR_SDA_PIN')  # e.g., 21
sensor_scl = params.get('SENSOR_SCL_PIN')  # e.g., 22
```

---

## Hardware Configuration Screen Features

### Device Models Supported
- ESP32-S3 (DevKit-C1)
- ESP32 (DevKit V1)
- ESP32-C3 (DevKit-M1)

### Module Types Available
1. LED (single/RGB)
2. Button/Switch
3. Relay
4. Buzzer
5. Sensor (Temperature, Humidity, Distance, etc.)
6. Display (OLED, LCD, TFT)
7. Motor (DC, Servo, Stepper)
8. Communication (UART, I2C, SPI)
9. Storage (SD Card)
10. Power Management
11. Custom modules

### Pin Assignment Features
- Manual pin selection
- Auto-assign algorithm (avoids conflicts)
- Pin validation (checks if pin is suitable for function)
- Pin conflict detection
- Ground (GND) pin support
- Multiple pins per module

### Code Generation
Users can generate C++ code snippets for:
- Pin definitions
- Module initialization
- Complete setup code

---

## ESP32 Firmware Integration

### Receiving Pin Mappings

The firmware receives pin mappings in the execute command:

```json
{
  "command": "execute_script",
  "script": "base64_encoded_script",
  "pin_mappings": {
    "LED_PIN": 23,
    "BUTTON_PIN": 5
  }
}
```

### Using Pin Mappings in MicroPython

The firmware should inject pin mappings into the script's global scope:

```python
# Firmware injects these before executing user script
params = {
  'LED_PIN': 23,
  'BUTTON_PIN': 5
}

# User script can then use them
led_pin = params.get('LED_PIN')
```

---

## Safety Features

1. **Pin Conflict Detection**: Prevents multiple modules from using the same pin
2. **Required Pin Validation**: Ensures all required pins are configured before running
3. **Pin Capability Checks**: Validates pins support the required function (e.g., I2C-capable pins)
4. **User Guidance**: Clear error messages with "Configure Hardware" button
5. **Hardware Profiles**: Save and load different configurations for different projects

---

## Benefits

### For Users
- **Safety**: No risk of incorrect wiring or pin conflicts
- **Flexibility**: Change hardware without modifying scripts
- **Reusability**: Configure once, run many tools
- **Guidance**: Clear instructions on what to connect

### For Developers
- **Simplicity**: No hardcoded pins in scripts
- **Portability**: Tools work on any hardware configuration
- **Documentation**: Pin requirements serve as wiring guide
- **Reliability**: App validates configuration before execution

---

## Example Use Cases

### 1. LED Blink Tool
- User adds LED module in Hardware Config
- Assigns Signal pin to GPIO23
- Runs LED Blink tool
- App injects LED_PIN=23
- Script blinks LED on GPIO23

### 2. Temperature Monitor
- User adds DHT11 sensor module
- Assigns Data pin to GPIO4
- Runs Temperature Monitor tool
- App injects SENSOR_PIN=4
- Script reads temperature from GPIO4

### 3. Smart Door Lock
- User adds:
  - Servo motor (Signal → GPIO18)
  - Button (Signal → GPIO15)
  - LED (Signal → GPIO2)
- Runs Door Lock tool
- App injects: SERVO_PIN=18, BUTTON_PIN=15, LED_PIN=2
- Script controls all components with configured pins

---

## Troubleshooting

### "Hardware Configuration Required" Dialog
**Cause**: Tool requires pins that aren't configured
**Solution**: 
1. Tap "Configure Hardware"
2. Add required modules
3. Assign pins
4. Return to tool and run again

### Pin Conflict Error
**Cause**: Two modules assigned to same pin
**Solution**: 
1. Open Hardware Config
2. Review pin assignments
3. Use "Auto Assign" or manually select different pins

### Script Can't Find Pin
**Cause**: Script looking for wrong variable name
**Solution**: 
1. Check manifest.json has correct "name" field
2. Verify script uses {NAME}_PIN format
3. Example: "LED" in manifest → use LED_PIN in script

---

## Future Enhancements

1. **Pin Templates**: Pre-configured templates for common projects
2. **Hardware Detection**: Auto-detect connected components
3. **Pin Testing**: Test individual pins before running tools
4. **Wiring Diagrams**: Visual guides showing how to connect components
5. **Cloud Sync**: Share hardware configurations across devices
6. **Community Configs**: Download configurations from other users

---

## Summary

The pin mapping system creates a seamless workflow:
1. **Connect** device
2. **Configure** hardware once
3. **Install** tools from marketplace
4. **Run** tools safely with automatic pin injection

This eliminates the traditional problems of:
- Hardcoded GPIO pins in scripts
- Wiring confusion
- Pin conflicts
- Unsafe execution

Users get a safe, flexible, and user-friendly experience, while developers can create portable, reusable tools.
