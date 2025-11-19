# DeZer0

**Open-source ESP32 Firmware Flashing and Tool Management Platform**

DeZer0 is a comprehensive platform designed for ESP32 device management, featuring a web-based firmware flasher, a Flutter mobile app for device control, and an extensible tool ecosystem. Flash firmware directly from your browser, manage tools, and control your ESP32 devices wirelessly.

## 📦 Repositories

- **[DeZer0](https://github.com/devkiraa/DeZer0)** - Main repository (web flasher, mobile app, ESP32 firmware)
- **[DeZer0-Tools](https://github.com/devkiraa/DeZer0-Tools)** - Community tools and app releases

## 🚀 Features

### Web Flasher
- **Browser-Based Flashing**: Flash ESP32 firmware directly from your browser using Web Serial API
- **Release Management**: Automatic firmware updates from GitHub releases
- **Real-time Progress**: Live flashing progress with detailed console output
- **Cross-Platform**: Works on Chrome, Edge, and Opera browsers

### Mobile App
- **Multi-Platform**: Flutter app for Android (iOS support coming soon)
- **Bluetooth & WiFi**: Connect to ESP32 via BLE or WiFi hotspot
- **Tool Marketplace**: Browse and install community tools directly to your device
- **Real-time Console**: View script output and device logs in real-time
- **Activity History**: Track your commands and device interactions
- **Connection Presets**: Save and manage multiple device connections
- **Favorites System**: Quick access to frequently used tools

### ESP32 Firmware
- **MicroPython Based**: Easy-to-modify Python-based firmware
- **Tool Execution**: Run Python scripts uploaded from the mobile app
- **WiFi Management**: Create hotspot or connect to existing networks
- **OTA Updates**: Over-the-air firmware updates support

## 📁 Project Structure

```
DeZer0/
├── web_flasher/          # Next.js web application for ESP32 firmware flashing
│   ├── src/
│   │   ├── app/         # Next.js pages (home, flasher, marketplace, download)
│   │   ├── components/  # React components
│   │   └── services/    # API services for GitHub integration
│   └── public/          # Static assets
│
├── dezero_app/          # Flutter mobile application
│   ├── lib/
│   │   ├── screens/     # App screens (device, tools, apps, etc.)
│   │   ├── services/    # BLE, WiFi, and marketplace services
│   │   ├── models/      # Data models
│   │   └── widgets/     # Reusable UI components
│   └── android/         # Android-specific configuration
│
├── firmware/            # ESP32 MicroPython firmware
│   ├── boot.py          # Boot configuration
│   ├── main.py          # Main application logic
│   └── lib/             # Required libraries (websockets, ssd1306)
│
└── .github/             # GitHub Actions workflows
```

## 🛠️ Getting Started

### Prerequisites

- **For Web Flasher**: Chrome 89+, Edge 89+, or Opera 75+ browser
- **For Mobile App**: Android 6.0+ device with Bluetooth 4.0 (BLE)
- **For ESP32**: ESP32 development board with USB connection

### Quick Start

#### 1. Flash Firmware

Visit the [Web Flasher](https://your-deployment-url.com/flasher) and follow these steps:

1. Connect your ESP32 to your computer via USB
2. Put ESP32 in bootloader mode (hold BOOT, press RESET, release BOOT)
3. Click "Connect Device" and select your ESP32 port
4. Select firmware version
5. Click "Flash Firmware" and wait for completion

#### 2. Install Mobile App

1. Download the latest APK from the [Download Page](https://your-deployment-url.com/download)
2. Enable "Install from Unknown Sources" in Android settings
3. Install the APK
4. Grant Bluetooth and Location permissions

#### 3. Connect and Use

1. Power on your ESP32 device
2. Open DeZer0 mobile app
3. Navigate to "Device" screen
4. Connect via Bluetooth or WiFi
5. Browse and install tools from the "Tools" marketplace
6. Run installed tools from the "Apps" screen

## 🔧 Development Setup

### Web Flasher

```bash
cd web_flasher
npm install
npm run dev
# Open http://localhost:3000
```

### Mobile App

```bash
cd dezero_app
flutter pub get
flutter run
```

### ESP32 Firmware

Upload the firmware files to your ESP32 using a tool like `ampy` or `rshell`:

```bash
cd firmware
ampy --port /dev/ttyUSB0 put boot.py
ampy --port /dev/ttyUSB0 put main.py
ampy --port /dev/ttyUSB0 put ssd1306.py
```

## 📱 Mobile App Features

### Device Management
- **BLE Scanner**: Discover nearby ESP32 devices
- **WiFi Hotspot**: Connect via ESP32's WiFi network
- **Connection Presets**: Save device configurations
- **Auto-reconnect**: Automatic reconnection on connection loss

### Tool Management
- **Marketplace Integration**: Browse GitHub-hosted tools
- **Category Filtering**: Tools organized by functionality
- **Search & Tags**: Find tools quickly
- **Download & Install**: One-tap tool installation
- **Favorites**: Mark frequently used tools

### Activity & Logs
- **Command History**: Track all executed commands
- **Execution Logs**: View detailed output
- **Timestamps**: See when actions occurred
- **Export Options**: Save logs for debugging

## 🌐 Web Flasher Features

### Firmware Flashing
- **GitHub Integration**: Auto-fetch latest releases
- **Version Selection**: Choose specific firmware versions
- **Dual File Flash**: Firmware + filesystem in one operation
- **Error Recovery**: Robust error handling and retry logic

### Tool Marketplace
- **Browse Tools**: Explore available ESP32 tools
- **Category Filters**: Network, RF, Utilities, etc.
- **Tool Details**: View descriptions, authors, and requirements
- **Installation Guide**: Step-by-step setup instructions

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Create Tools**: Build Python scripts for ESP32 with a `manifest.json`
2. **Report Bugs**: Open issues on GitHub
3. **Submit PRs**: Fix bugs or add features
4. **Documentation**: Improve guides and examples

### Creating a Tool

Create a new directory in `DeZer0-Tools` repository with:

```json
// manifest.json
{
  "id": "my-tool",
  "name": "My Awesome Tool",
  "version": "1.0.0",
  "author": "Your Name",
  "description": "What your tool does",
  "category": "Utilities",
  "scriptFilename": "my_tool.py",
  "tags": ["tag1", "tag2"]
}
```

```python
# my_tool.py
print("Hello from my tool!")
# Your ESP32 Python code here
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Links

- **GitHub Repository**: [devkiraa/DeZer0](https://github.com/devkiraa/DeZer0)
- **Tools Repository**: [devkiraa/DeZer0-Tools](https://github.com/devkiraa/DeZer0-Tools)
- **Web Flasher**: [Live Demo](#)
- **Report Issues**: [GitHub Issues](https://github.com/devkiraa/DeZer0/issues)
- **Discussions**: [GitHub Discussions](https://github.com/devkiraa/DeZer0/discussions)

## 🙏 Acknowledgments

- ESP32 community for hardware support
- Flutter team for the amazing framework
- Next.js team for the web framework
- MicroPython community for ESP32 firmware
- All contributors and tool creators

## 📊 System Requirements

### Web Flasher
- Chrome 89+, Edge 89+, or Opera 75+
- USB connection to ESP32
- 50MB free disk space

### Mobile App
- **Minimum**: Android 6.0, Bluetooth 4.0, 50MB storage
- **Recommended**: Android 8.0+, Bluetooth 5.0, 100MB storage
- Location permission (required for BLE scanning)
- WiFi for marketplace access

### ESP32 Firmware
- ESP32 development board
- 4MB flash memory
- WiFi capability
- Optional: OLED display (SSD1306)

---

**Made with ❤️ by the DeZer0 Community**
