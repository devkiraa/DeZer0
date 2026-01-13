# Hardware Configuration System

## Overview
The Hardware Configuration system provides a comprehensive solution for managing ESP32 hardware module configurations, including GPIO pin assignments, auto-allocation, validation, and code generation.

## Features

### 1. Hardware Module Management
- **15 Supported Module Types**: OLED, PN532, CC1101, LoRa, Buzzer, LED, Button, Relay, Camera, GPS, SD Card, I2C Sensor, SPI Device, UART, Custom
- **Pin Requirements**: Each module defines required/optional pins with modes and preferred GPIO numbers
- **Enable/Disable**: Toggle modules on/off without deleting configuration
- **Module Templates**: Pre-configured templates with sensible defaults for common modules

### 2. Multi-Device Support
- **ESP32-S3**: 48 GPIO pins with 39 usable pins defined
- **ESP32 Classic**: 35 GPIO pins with 25 usable pins defined
- **ESP32-C3**: 21 GPIO pins with 14 usable pins defined

### 3. Pin Management
- **Pin Capabilities**: GPIO, ADC, DAC, Touch, PWM, I2C, SPI, UART, RTC
- **Pin Restrictions**: Boot pins, flash pins, strapping pins marked with restrictions
- **Pin Validation**: Checks for conflicts, mode compatibility, and restrictions
- **Manual Assignment**: Dropdown selectors with filtered available pins per mode
- **Auto Assignment**: Intelligent algorithm that groups protocol pins (I2C/SPI/UART)

### 4. Auto Pin Allocation Algorithm
The auto-assignment algorithm intelligently allocates pins based on:
- **Preferred Pins**: Uses module-specified preferred pins first
- **Pin Capabilities**: Ensures pin supports required mode (I2C, SPI, UART, etc.)
- **Protocol Grouping**: Groups I2C pins (SCL/SDA) together, same for SPI and UART
- **Conflict Avoidance**: Checks for already-used pins
- **Usability Checks**: Avoids restricted pins (boot, flash, strapping)

Example grouping:
```
I2C: GPIO21/22 (ESP32), GPIO8/9 (ESP32-S3)
SPI: GPIO33-37 (ESP32-S3)
UART: GPIO19/20 (ESP32-S3)
```

### 5. Validation System
Validates configurations for:
- **Duplicate Pin Usage**: Multiple modules using same pin
- **Pin Compatibility**: Pin supports required mode
- **Restricted Pins**: Warns about boot/flash/strapping pins
- **Device Compatibility**: Pin exists on selected device model

### 6. Code Generation
Generates deployment-ready code in multiple formats:

#### Python Code
```python
from machine import Pin, I2C, SPI, UART

# Pin Configuration
PINS = {
    "oled1": {
        "SDA": 21,
        "SCL": 22,
    },
    "led1": {
        "Signal": 2,
    },
}

# Module Initialization
i2c = I2C(0, scl=Pin(PINS["oled1"]["SCL"]), sda=Pin(PINS["oled1"]["SDA"]))
led_led1 = Pin(PINS["led1"]["Signal"], Pin.OUT)
```

#### C++ Code
```cpp
// Hardware Configuration for ESP32-S3
#ifndef HARDWARE_CONFIG_H
#define HARDWARE_CONFIG_H

#include <Arduino.h>

// OLED Display
#define OLED1_SDA 21
#define OLED1_SCL 22

// LED
#define LED1_SIGNAL 2

#endif // HARDWARE_CONFIG_H
```

#### JSON Config
```json
{
  "device_model": "ESP32-S3",
  "modules": [...],
  "pin_assignments": {...},
  "last_modified": "2024-01-15T10:30:00.000Z",
  "firmware_version": "1.0.0"
}
```

### 7. Device Information Display
Shows real-time device stats:
- Chip Model (ESP32-S3, ESP32, ESP32-C3)
- MAC Address
- Flash Size (MB)
- Free Heap Memory (KB)
- Firmware Version

### 8. Cloud Synchronization
- **Fetch from Device**: Download current config from ESP32 via HTTP
- **Upload to Device**: Push configuration to ESP32 with immediate effect
- **Local Storage**: Persist config locally using SharedPreferences
- **Offline Mode**: Work with configurations without device connection

## Architecture

### Data Models (`lib/models/`)

#### `hardware_config.dart`
```dart
class HardwareConfig {
  String deviceModel;              // ESP32-S3, ESP32, ESP32-C3
  List<HardwareModule> modules;    // Configured modules
  Map<int, PinAssignment> pinAssignments;  // Pin -> Assignment mapping
  DateTime lastModified;
  String firmwareVersion;
}

class HardwareModule {
  String id;                       // Unique identifier
  ModuleType type;                 // Module type enum
  String name;                     // Display name
  List<PinRequirement> pinRequirements;  // Required pins
  Map<String, dynamic> settings;   // Module-specific settings
  bool enabled;                    // Enable/disable flag
}

class PinAssignment {
  int pin;                         // GPIO number
  String moduleId;                 // Module using this pin
  String function;                 // Pin function (SDA, SCL, etc.)
  PinMode mode;                    // Pin mode (I2C, SPI, etc.)
}

class PinRequirement {
  String function;                 // Pin function name
  PinMode mode;                    // Required mode
  bool required;                   // Is this pin required?
  List<int>? preferredPins;        // Preferred GPIO numbers
}

class DeviceInfo {
  String chipModel;
  int flashSize;
  String firmwareVersion;
  String macAddress;
  int totalHeap;
  int freeHeap;
  int psramSize;
  int availableStorage;
  int? batteryPercentage;
  bool connected;
}
```

#### `esp32_pins.dart`
```dart
class ESP32Pin {
  int number;                      // GPIO number
  List<PinCapability> capabilities; // Supported capabilities
  bool isRestricted;               // Boot/flash/strapping pin
  String? restriction;             // Restriction reason
  
  bool get isUsable => !isRestricted;
  bool supportsMode(PinMode mode) { /* ... */ }
}

class ESP32PinDefinitions {
  static List<ESP32Pin> getPinsForModel(String model) {
    // Returns pin list for ESP32-S3, ESP32, or ESP32-C3
  }
}

class ModuleTemplates {
  static HardwareModule createModule(ModuleType type, String id) {
    // Returns pre-configured module template
  }
}
```

### Service Layer (`lib/services/`)

#### `hardware_config_service.dart`
```dart
class HardwareConfigService {
  static final instance = HardwareConfigService._internal();
  
  // State Management
  ValueNotifier<HardwareConfig?> currentConfig;
  ValueNotifier<DeviceInfo?> deviceInfo;
  
  // Cloud Operations
  Future<HardwareConfig> fetchConfigFromDevice(String deviceIP);
  Future<void> uploadConfigToDevice(String deviceIP, HardwareConfig config);
  Future<DeviceInfo> fetchDeviceInfo(String deviceIP);
  
  // Pin Management
  Map<int, PinAssignment> autoAssignPins(String deviceModel, List<HardwareModule> modules);
  List<String> validatePinAssignments(Map<int, PinAssignment> assignments, String deviceModel);
  
  // Code Generation
  String generatePythonCode(HardwareConfig config);
  String generateCppCode(HardwareConfig config);
  String generateJsonConfig(HardwareConfig config);
  
  // Configuration Management
  HardwareConfig createDefaultConfig(String deviceModel);
  HardwareConfig addModule(HardwareConfig config, HardwareModule module);
  HardwareConfig removeModule(HardwareConfig config, String moduleId);
  HardwareConfig updatePinAssignment(HardwareConfig config, ...);
}
```

### UI Layer (`lib/screens/`)

#### `hardware_config_screen.dart`
- **Main View**: Device info, module list, validation errors
- **Module Cards**: Expandable cards with pin selectors
- **Add Module Dialog**: Module type selection with templates
- **Code View Dialog**: Generated code with copy-to-clipboard
- **Floating Action Buttons**: Add module, auto-assign, upload

## API Endpoints (ESP32 Firmware)

### GET `/api/device/info`
Returns device information:
```json
{
  "chip_model": "ESP32-S3",
  "flash_size": 8388608,
  "firmware_version": "1.0.0",
  "mac_address": "AA:BB:CC:DD:EE:FF",
  "available_storage": 1048576,
  "battery_percentage": 85,
  "connected": true,
  "total_heap": 327680,
  "free_heap": 245760,
  "psram_size": 8388608
}
```

### GET `/api/hardware/config`
Returns current hardware configuration:
```json
{
  "device_model": "ESP32-S3",
  "modules": [
    {
      "id": "oled1",
      "type": "oled",
      "name": "OLED Display",
      "pin_requirements": [
        {
          "function": "SDA",
          "mode": "i2c",
          "required": true,
          "preferred_pins": [21, 8]
        }
      ],
      "settings": {"width": 128, "height": 64, "address": "0x3C"},
      "enabled": true
    }
  ],
  "pin_assignments": {
    "21": {
      "pin": 21,
      "module_id": "oled1",
      "function": "SDA",
      "mode": "i2c"
    }
  },
  "last_modified": "2024-01-15T10:30:00.000Z",
  "firmware_version": "1.0.0"
}
```

### POST `/api/hardware/config`
Upload new configuration. Returns 200 OK on success.

## Usage Guide

### 1. Creating a Configuration
```dart
// Navigate to hardware config screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => HardwareConfigScreen(deviceIP: '192.168.4.1'),
  ),
);
```

### 2. Adding Modules
1. Tap the `+` FAB
2. Select module type from dropdown
3. Optionally customize name
4. Tap "Add"

### 3. Assigning Pins
**Manual Assignment:**
1. Expand module card
2. Select pin from dropdown for each function
3. Dropdowns show only compatible pins
4. Used pins are marked

**Auto Assignment:**
1. Add all desired modules
2. Tap the magic wand FAB (⚡)
3. Algorithm assigns pins intelligently
4. Review and adjust if needed

### 4. Validating Configuration
- Validation runs automatically on changes
- Warnings appear at top if issues found
- Cannot upload until validation passes

### 5. Uploading to Device
1. Ensure device IP is available
2. Verify no validation errors
3. Tap upload FAB (☁️)
4. Configuration syncs to ESP32

### 6. Generating Code
1. Tap code icon (`<>`) in app bar
2. Select format (Python/C++/JSON)
3. View generated code
4. Copy to clipboard
5. Deploy to your project

## Integration Examples

### ESP32 Firmware (C++)
```cpp
#include "hardware_config.h"

void setup() {
  // Initialize OLED
  Wire.begin(OLED1_SDA, OLED1_SCL);
  
  // Initialize LED
  pinMode(LED1_SIGNAL, OUTPUT);
  
  // Initialize button
  pinMode(BUTTON1_INPUT, INPUT_PULLUP);
}
```

### MicroPython
```python
from hardware_config import PINS
import machine

# Initialize from generated config
i2c = machine.I2C(0, scl=machine.Pin(PINS["oled1"]["SCL"]), 
                     sda=machine.Pin(PINS["oled1"]["SDA"]))
```

### Flutter App Integration
```dart
// Fetch config before running payload
final config = await HardwareConfigService.instance
    .fetchConfigFromDevice(deviceIP);

// Pass pin assignments to payload
final pinMapping = {
  'oled_sda': config.pinAssignments.values
      .firstWhere((a) => a.moduleId == 'oled1' && a.function == 'SDA')
      .pin,
};

await payloadService.executePayload(
  deviceIP, 
  payloadId, 
  parameters: pinMapping,
);
```

## Pin Reference Tables

### ESP32-S3 (48 GPIO)
| GPIO | ADC | DAC | Touch | PWM | I2C | SPI | UART | Notes |
|------|-----|-----|-------|-----|-----|-----|------|-------|
| 0    | ✓   |     |       | ✓   | ✓   | ✓   | ✓    | Boot button |
| 8-9  |     |     |       | ✓   | ✓   |     |      | I2C default |
| 21-22|     |     |       | ✓   | ✓   |     |      | I2C alt |
| 33-37|     |     |       | ✓   |     | ✓   |      | SPI default |
| 43-44|     |     |       |     |     |     |      | UART0 (console) |

### ESP32 Classic (35 GPIO)
| GPIO | ADC | DAC | Touch | PWM | I2C | SPI | UART | Notes |
|------|-----|-----|-------|-----|-----|-----|------|-------|
| 21-22|     |     |       | ✓   | ✓   |     |      | I2C default |
| 18-23|     |     |       | ✓   |     | ✓   |      | SPI default |
| 34-39| ✓   |     |       |     |     |     |      | Input only |

### ESP32-C3 (21 GPIO)
| GPIO | ADC | PWM | I2C | SPI | UART | Notes |
|------|-----|-----|-----|-----|------|-------|
| 8-9  |     | ✓   | ✓   |     |      | I2C default |
| 20-21|     |     |     |     | ✓    | UART0 (console) |

## Best Practices

### 1. Pin Selection
- Use auto-assignment first, then fine-tune manually
- Avoid GPIO0, GPIO2, GPIO12 on ESP32 (strapping pins)
- Reserve ADC pins for analog sensors
- Group I2C devices on same bus when possible
- Keep high-frequency signals (SPI) away from sensitive inputs

### 2. Module Organization
- Use descriptive module names (e.g., "Front LED" vs "LED1")
- Group related modules by function
- Disable unused modules instead of deleting
- Document special settings in module config

### 3. Configuration Management
- Always fetch from device before making changes
- Validate before uploading
- Keep backup configurations locally
- Test incrementally (add one module at a time)

### 4. Code Generation
- Generate code after finalizing configuration
- Review generated code for optimization opportunities
- Add error handling around generated initialization code
- Consider power consumption in pin selections

## Troubleshooting

### Validation Errors
**"Pin X is used by multiple modules"**
- Manually reassign one of the conflicting modules
- Run auto-assign to generate conflict-free layout

**"Pin X does not support Y mode"**
- Check pin capabilities table for device model
- Select different pin with required capability
- Use auto-assign to find compatible pins

**"Pin X is restricted"**
- Avoid using boot, flash, or strapping pins
- If necessary, understand implications for boot process
- Consider using alternate pins

### Connection Issues
**"Failed to fetch from device"**
- Verify device IP is correct
- Check WiFi connection
- Ensure ESP32 HTTP server is running
- Check firewall settings

**"Upload failed"**
- Ensure configuration passes validation
- Verify device has sufficient storage
- Check ESP32 is not running critical task
- Retry after device reboot

### Auto-Assignment Issues
**"Not enough pins available"**
- Remove unnecessary modules
- Use shared I2C/SPI buses
- Check for invalid pin restrictions
- Switch to device with more GPIOs

## Future Enhancements
- [ ] Visual pin diagram with click-to-assign
- [ ] Configuration presets for common setups
- [ ] Pin conflict resolution suggestions
- [ ] Hardware testing mode (toggle pins to verify connections)
- [ ] Import/export configuration files
- [ ] Version control for configurations
- [ ] Multi-device configuration management
- [ ] Power consumption calculator
- [ ] Custom module type creation
- [ ] Integration with hardware marketplace

## File Structure
```
mobile/
├── lib/
│   ├── models/
│   │   ├── hardware_config.dart      # Data models
│   │   └── esp32_pins.dart           # Pin definitions
│   ├── services/
│   │   └── hardware_config_service.dart  # Business logic
│   └── screens/
│       └── hardware_config_screen.dart   # UI implementation
└── HARDWARE_CONFIG.md               # This documentation
```

## Dependencies
- `flutter/material.dart` - UI framework
- `http` - HTTP client for ESP32 communication
- `shared_preferences` - Local storage
- `flutter/services.dart` - Clipboard operations

## License
Part of the DeZero ESP32 Hacking Tool Suite
