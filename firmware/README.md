# DeZer0 Firmware - ESP-IDF Project

Modern modular firmware system for ESP32 with dynamic payload loading.

## Features

- **Modular Plugin System** - Load and execute payloads dynamically
- **Multiple Runtime Support** - Native C++, MicroPython (.mpy), Lua scripts
- **Hardware APIs** - WiFi, BLE, GPIO, Display abstractions
- **OTA Updates** - Over-the-air firmware updates
- **BLE/WiFi Communication** - Control via mobile app
- **Secure Execution** - Sandboxed payload execution with resource limits

## Build Requirements

- ESP-IDF v5.0 or later
- Python 3.8+
- CMake 3.16+

## Quick Start

```bash
# Set up ESP-IDF environment
. $HOME/esp/esp-idf/export.sh

# Configure project
idf.py menuconfig

# Build firmware
idf.py build

# Flash to device
idf.py -p /dev/ttyUSB0 flash monitor
```

## Flash Partition Layout

| Partition | Type | Offset | Size | Description |
|-----------|------|--------|------|-------------|
| bootloader | app | 0x1000 | 32K | Bootloader |
| partition_table | data | 0x8000 | 4K | Partition table |
| otadata | data | 0x9000 | 8K | OTA data |
| phy_init | data | 0xB000 | 4K | PHY init data |
| factory | app | 0x10000 | 1.5M | Main firmware |
| ota_0 | app | 0x190000 | 1.5M | OTA slot 0 |
| ota_1 | app | 0x310000 | 1.5M | OTA slot 1 |
| storage | data/spiffs | 0x490000 | 3M | Payload storage |

## Directory Structure

```
firmware/
├── main/                   # Main application
│   ├── core/              # Core system
│   ├── hal/               # Hardware abstraction
│   ├── runtimes/          # Payload loaders
│   └── communication/     # BLE/WiFi
├── components/            # ESP-IDF components
└── sdkconfig             # Configuration
```

## Payload Development

See `/tools-sdk` for payload development templates and API documentation.

## License

MIT License - See LICENSE file
