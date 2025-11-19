# DeZer0

**Open-source ESP32 Security Research & Tool Management Platform**

DeZer0 is a powerful ESP32-based platform for wireless security research, featuring a modular firmware system with plugin support, a web-based firmware flasher, and a Flutter mobile app for device control. Execute custom payloads with support for Native C++, MicroPython, and Lua runtimes.

## 📦 Repositories

- **[DeZer0](https://github.com/devkiraa/DeZer0)** - Main repository (source code, web flasher, mobile app, firmware)
- **[DeZer0-Tools](https://github.com/devkiraa/DeZer0-Tools)** - Community tools marketplace and app releases

## 🚀 Features

### Web Flasher
- **Browser-Based Flashing**: Flash ESP32 firmware directly from your browser using Web Serial API
- **Release Management**: Automatic firmware updates from GitHub releases
- **Real-time Progress**: Live flashing progress with detailed console output
- **Cross-Platform**: Works on Chrome, Edge, and Opera browsers
- **Tools Marketplace**: Browse and download community tools with Vercel Blob caching

### Mobile App
- **Multi-Platform**: Flutter app for Android (iOS support coming soon)
- **Bluetooth & WiFi**: Connect to ESP32 via BLE or WiFi
- **Tool Marketplace**: Browse, download, and install community payloads
- **Payload Management**: Upload, execute, and manage custom payloads
- **Real-time Monitoring**: View payload output and device logs
- **App Updates**: Automatic update checking from DeZer0-Tools releases
- **Modern UI**: Redesigned sidebar with gradient effects and status indicators

### ESP32 Firmware v2.0 (NEW!)
- **Modular Plugin System**: Dynamic payload loading with sandboxed execution
- **Multiple Runtimes**: Support for Native C++ (.so), MicroPython (.mpy), and Lua (.lua)
- **Hardware APIs**: WiFi, BLE, GPIO, Display (SSD1306), Storage
- **OTA Updates**: Dual-partition OTA with rollback support
- **Resource Management**: Memory and execution time limits per payload
- **Permission System**: Fine-grained permissions for security
- **Built-in Modules**: WiFi scanner, BLE scanner included

## 📁 Project Structure

```
DeZer0/
├── web_flasher/          # Next.js web application for ESP32 firmware flashing
│   ├── src/
│   │   ├── app/         # Next.js pages (home, flasher, marketplace, download)
│   │   ├── components/  # React components
│   │   └── services/    # API services (GitHub, marketplace, Vercel Blob)
│   └── public/          # Static assets
│
├── dezero_app/          # Flutter mobile application
│   ├── lib/
│   │   ├── screens/     # App screens (device, tools, apps, updates)
│   │   ├── services/    # BLE, WiFi, app management, and marketplace services
│   │   ├── models/      # Data models
│   │   └── widgets/     # Reusable UI components
│   └── android/         # Android-specific configuration
│
├── firmware/            # ESP-IDF C++ firmware (v2.0)
│   ├── main/
│   │   ├── core/        # Boot manager, plugin manager, storage manager
│   │   ├── hal/         # Hardware abstraction (WiFi, BLE, GPIO, Display)
│   │   ├── communication/ # BLE server, WiFi manager, WebSocket
│   │   ├── runtimes/    # Native, MicroPython, Lua payload loaders
│   │   └── builtins/    # Built-in modules (WiFi/BLE scanners)
│   ├── CMakeLists.txt   # Build configuration
│   ├── partitions.csv   # Flash partition table
│   └── BUILD_GUIDE.md   # Firmware build instructions
│
├── build_firmware.py    # Automated firmware build script
│
└── .github/             # GitHub Actions workflows
```

## 🛠️ Getting Started

### Prerequisites

- **For Web Flasher**: Chrome 89+, Edge 89+, or Opera 75+ browser
- **For Mobile App**: Android 6.0+ device with Bluetooth 4.0 (BLE)
- **For Firmware Build**: ESP-IDF v5.0+, Python 3.8+, CMake 3.16+
- **For Flashing**: ESP32 development board with USB connection

### Quick Start

#### 1. Build Firmware (NEW!)

```bash
# Clone repository
git clone https://github.com/devkiraa/DeZer0.git
cd DeZer0

# Setup ESP-IDF environment
# Windows PowerShell:
. $env:IDF_PATH\export.ps1
# Linux/macOS:
. $HOME/esp/esp-idf/export.sh

# Build firmware with automated script
python build_firmware.py

# Binaries will be in firmware_bins/ directory
```

#### 2. Flash Firmware

**Option A: Using Web Flasher (Recommended)**

Visit the [Web Flasher](https://your-deployment-url.com/flasher) and follow these steps:

1. Connect your ESP32 to your computer via USB
2. Put ESP32 in bootloader mode (hold BOOT, press RESET, release BOOT)
3. Click "Connect Device" and select your ESP32 port
4. Select firmware version from releases
5. Click "Flash Firmware" and wait for completion

**Option B: Using Build Script (Development)**

```bash
cd firmware_bins
# Windows:
.\flash.ps1 COM3
# Linux/macOS:
./flash.sh /dev/ttyUSB0
```

**Option C: Manual with esptool**

```bash
esptool.py --chip esp32 --port COM3 --baud 460800 write_flash -z \
  0x1000 bootloader.bin \
  0x8000 partition-table.bin \
  0x10000 dezero_firmware.bin
```

#### 3. Install Mobile App

1. Download the latest APK from [DeZer0-Tools Releases](https://github.com/devkiraa/DeZer0-Tools/releases)
2. Enable "Install from Unknown Sources" in Android settings
3. Install the APK
4. Grant Bluetooth and Location permissions

#### 4. Connect and Use

1. Power on your ESP32 device (will show "DeZero v2.0" on display)
2. Open DeZer0 mobile app
3. Navigate to "Device" screen
4. Connect via Bluetooth (device name: "DeZero")
5. Browse payloads from "Tools" marketplace
6. Upload and execute payloads
7. Monitor execution in real-time

## 🔧 Development

### Building Firmware

See [firmware/BUILD_GUIDE.md](firmware/BUILD_GUIDE.md) for detailed build instructions.

Quick build:
```bash
python build_firmware.py
```

Incremental build (faster):
```bash
python build_firmware.py --no-clean
```

### Creating Payloads

See [firmware/payloads/README.md](firmware/payloads/README.md) for payload development guide.

Three runtime types supported:
1. **Native C++** (.so) - Maximum performance, compiled code
2. **MicroPython** (.mpy) - Python scripts, cross-compiled
3. **Lua** (.lua) - Lua scripts, interpreted

All payloads use the same API defined in `firmware/main/include/payload_api.h`.

## 💻 Development Setup

### Web Flasher

```bash
cd web_flasher
npm install
npm run dev
# Open http://localhost:3000
```

#### Vercel Blob Cache Setup
```bash
# Set environment variable
BLOB_READ_WRITE_TOKEN=your_token_here

# Manual sync (or wait for cron)
curl http://localhost:3000/api/tools/sync
```

### Mobile App

```bash
cd dezero_app
flutter pub get
flutter run -d <device_id>
```

### Firmware Development

See [firmware/BUILD_GUIDE.md](firmware/BUILD_GUIDE.md) for complete guide.

```bash
cd firmware
idf.py build
idf.py -p COM3 flash monitor
```

## 📱 Mobile App Features

### Device Management
- **BLE Connection**: Discover and connect to ESP32 via Bluetooth
- **WiFi Connection**: Connect via WiFi (future feature)
- **Real-time Status**: Connection state and battery level
- **Device Info**: Firmware version, uptime, memory usage

### Payload Management
- **Marketplace Browser**: Browse community payloads from DeZer0-Tools
- **Category Filtering**: WiFi, Bluetooth, GPIO, Security, etc.
- **Upload Payloads**: Install custom payloads to device
- **Execute & Monitor**: Run payloads and view real-time output
- **Parameter Configuration**: Set payload parameters before execution

### System Features
- **App Updates**: Check for new app versions from DeZer0-Tools
- **Settings**: Configure app behavior and device preferences
- **Modern UI**: Gradient sidebar with status indicators
- **Activity Tracking**: Monitor payload execution history

## 🌐 Web Flasher Features

### Firmware Flashing
- **GitHub Integration**: Auto-fetch releases from DeZer0-Tools
- **Version Selection**: Choose specific firmware versions
- **Web Serial API**: Browser-based flashing (no drivers needed)
- **Error Recovery**: Robust error handling and retry logic
- **Progress Tracking**: Real-time flashing progress

### Tool Marketplace
- **Vercel Blob Cache**: Instant loading with 6-hour auto-sync
- **Browse Payloads**: Explore 55+ community payloads
- **Category Filters**: WiFi, Bluetooth, Radio, GPIO, Security, etc.
- **Search**: Find payloads by name, description, or tags
- **Pagination**: Smooth browsing with 12 items per page
- **Direct Download**: Download payload packages for offline use
- **Tool Details**: View descriptions, authors, and requirements
- **Installation Guide**: Step-by-step setup instructions

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Create Payloads**: Build tools using Native C++, MicroPython, or Lua with a `manifest.json`
2. **Report Bugs**: Open issues on GitHub
3. **Submit PRs**: Fix bugs, add features, or improve firmware
4. **Documentation**: Improve guides and examples
5. **Testing**: Test firmware on different ESP32 variants

### Creating a Payload

See [firmware/payloads/README.md](firmware/payloads/README.md) for complete guide.

Example manifest for a MicroPython payload:

```json
{
  "id": "my-payload",
  "name": "My Awesome Payload",
  "version": "1.0.0",
  "author": "Your Name",
  "description": "What your payload does",
  "category": "Utilities",
  "payload": {
    "type": "micropython",
    "runtime": "micropython",
    "entry": "payload",
    "size": 8192
  },
  "requirements": {
    "min_firmware_version": "2.0.0",
    "apis": ["wifi", "display"],
    "memory_kb": 32,
    "storage_kb": 5
  },
  "permissions": ["wifi_scan", "display_write"],
  "parameters": [
    {
      "name": "duration",
      "type": "integer",
      "label": "Scan Duration (seconds)",
      "default": "10"
    }
  ]
}
```

Submit to [DeZer0-Tools](https://github.com/devkiraa/DeZer0-Tools) repository.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Links

- **GitHub Repository**: [devkiraa/DeZer0](https://github.com/devkiraa/DeZer0)
- **Tools Repository**: [devkiraa/DeZer0-Tools](https://github.com/devkiraa/DeZer0-Tools)
- **Report Issues**: [GitHub Issues](https://github.com/devkiraa/DeZer0/issues)
- **Discussions**: [GitHub Discussions](https://github.com/devkiraa/DeZer0/discussions)

## 🙏 Acknowledgments

- ESP32 community for hardware support and ESP-IDF framework
- Flutter team for cross-platform mobile framework
- Next.js and Vercel teams for web framework and hosting
- Flipper Zero and ESP32 Marauder projects for inspiration
- All contributors and payload creators

## 📊 System Requirements

### Firmware Build
- ESP-IDF v5.0 or later
- Python 3.8+
- CMake 3.16+
- 2GB RAM minimum
- 5GB disk space for ESP-IDF

### Web Flasher
- Chrome 89+, Edge 89+, or Opera 75+ (Web Serial API support)
- USB connection to ESP32
- 10MB free disk space

### Mobile App
- **Minimum**: Android 6.0, Bluetooth 4.0 (BLE), 50MB storage
- **Recommended**: Android 8.0+, Bluetooth 5.0, 100MB storage

### ESP32 Hardware
- ESP32 (original), ESP32-S2, ESP32-S3, or ESP32-C3
- 4MB flash minimum (8MB recommended)
- USB cable with data lines (not charge-only)
- Optional: SSD1306 OLED display (128x64)
- Location permission (required for BLE scanning)
- WiFi for marketplace access

### ESP32 Firmware
- ESP32 development board
- 4MB flash memory
- WiFi capability
- Optional: OLED display (SSD1306)

---

**Made with ❤️ by the DeZer0 Community**
