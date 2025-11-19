# DeZero Firmware v2.0 - Build Guide

## Quick Start

### Prerequisites
- ESP-IDF v5.0 or later installed
- Python 3.8+
- CMake 3.16+
- ESP32 development board

### Setup ESP-IDF Environment

**Windows (PowerShell):**
```powershell
cd C:\esp\esp-idf
.\export.ps1
```

**Linux/macOS:**
```bash
. $HOME/esp/esp-idf/export.sh
```

### Build Commands

1. **Configure the project:**
```bash
cd firmware
idf.py set-target esp32
idf.py menuconfig  # Optional: customize configuration
```

2. **Build the firmware:**
```bash
idf.py build
```

3. **Flash to device:**
```bash
idf.py -p COM3 flash  # Replace COM3 with your port
```

4. **Monitor serial output:**
```bash
idf.py -p COM3 monitor
```

5. **Flash and monitor (combined):**
```bash
idf.py -p COM3 flash monitor
```

## Project Structure

```
firmware/
├── CMakeLists.txt              # Root build configuration
├── partitions.csv              # Flash partition table
├── sdkconfig.defaults          # Default ESP32 configuration
├── README.md                   # Project documentation
└── main/
    ├── CMakeLists.txt          # Main component configuration
    ├── main.cpp                # Application entry point
    ├── include/
    │   ├── types.h             # Core type definitions
    │   └── payload_api.h       # Payload API interface
    ├── core/                   # Core system components
    │   ├── boot_manager.*      # Boot and OTA management
    │   ├── storage_manager.*   # SPIFFS filesystem
    │   ├── plugin_manager.*    # Payload discovery/loading
    │   └── payload_loader.*    # Runtime execution
    ├── hal/                    # Hardware Abstraction Layer
    │   ├── wifi_api.*          # WiFi operations
    │   ├── ble_api.*           # Bluetooth LE operations
    │   ├── gpio_api.*          # GPIO control
    │   └── display_api.*       # SSD1306 display driver
    ├── communication/          # Communication protocols
    │   ├── ble_server.*        # BLE GATT server
    │   ├── wifi_manager.*      # WiFi AP/STA management
    │   └── websocket_server.*  # WebSocket for mobile app
    ├── runtimes/               # Payload execution engines
    │   ├── native_loader.*     # Native C/C++ (.so)
    │   ├── micropython_vm.*    # MicroPython (.mpy)
    │   └── lua_vm.*            # Lua scripts (.lua)
    └── builtins/               # Built-in modules
        ├── wifi_scanner.*      # WiFi network scanner
        └── ble_scanner.*       # BLE device scanner
```

## Flash Partitions

| Name      | Type | SubType | Offset   | Size   | Purpose               |
|-----------|------|---------|----------|--------|-----------------------|
| nvs       | data | nvs     | 0x9000   | 16K    | Non-volatile storage  |
| otadata   | data | ota     | 0xd000   | 8K     | OTA data partition    |
| phy_init  | data | phy     | 0xf000   | 4K     | PHY init data         |
| factory   | app  | factory | 0x10000  | 1.5M   | Factory app           |
| ota_0     | app  | ota_0   | 0x190000 | 1.5M   | OTA slot 0            |
| ota_1     | app  | ota_1   | 0x310000 | 1.5M   | OTA slot 1            |
| storage   | data | spiffs  | 0x490000 | 3M     | Payload storage       |

## Configuration Options

### WiFi Settings
- Edit `sdkconfig.defaults` to change WiFi buffer sizes
- Configure in `menuconfig` under "Component config → Wi-Fi"

### Bluetooth Settings
- BLE-only mode enabled by default
- Configure in `menuconfig` under "Component config → Bluetooth"

### Memory Optimization
- Default: 240MHz CPU, optimization for performance
- Change in `menuconfig` under "Compiler options"

## Troubleshooting

### Build Errors

**Error: "esp_netif.h not found"**
- Ensure ESP-IDF v5.0+ is installed
- Run `idf.py fullclean` and rebuild

**Error: "undefined reference to..."**
- Check CMakeLists.txt has all source files listed
- Verify component dependencies are correct

### Flash Errors

**Error: "A fatal error occurred: Failed to connect"**
- Check USB cable connection
- Hold BOOT button while connecting
- Verify correct COM port

**Error: "Partition table does not fit"**
- Check partitions.csv total size doesn't exceed flash size
- ESP32 typically has 4MB flash

### Runtime Issues

**Device not booting:**
- Erase flash: `idf.py -p COM3 erase-flash`
- Reflash bootloader and app
- Check power supply (min 500mA)

**BLE not working:**
- Verify `CONFIG_BT_ENABLED=y` in sdkconfig
- Check antenna connection on ESP32 module

**SPIFFS mount failed:**
- Format partition: First boot will auto-format
- Check partition table matches sdkconfig

## Development Workflow

1. **Make code changes** in source files
2. **Build:** `idf.py build`
3. **Flash:** `idf.py -p COM3 flash`
4. **Monitor:** `idf.py -p COM3 monitor`
5. **Debug:** Use ESP-IDF logging (ESP_LOGI, ESP_LOGE, etc.)

## Next Steps

- [ ] Implement MicroPython VM integration
- [ ] Implement Lua VM integration
- [ ] Add native payload dynamic loading (.so)
- [ ] Complete BLE GATT service with characteristics
- [ ] Implement WebSocket protocol for mobile app
- [ ] Create example payloads for each runtime
- [ ] Add unit tests
- [ ] Implement security/sandboxing
- [ ] Add OTA update via mobile app

## Resources

- [ESP-IDF Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/)
- [ESP32 Technical Reference](https://www.espressif.com/sites/default/files/documentation/esp32_technical_reference_manual_en.pdf)
- [DeZer0 GitHub Repository](https://github.com/devkiraa/DeZer0)
