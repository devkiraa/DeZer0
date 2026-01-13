# DeZero Firmware Quick Start Guide

This guide will help you build the DeZero ESP32 firmware from source and flash it to your device.

## 📋 Prerequisites

Before building the firmware, ensure you have:

1. **ESP-IDF v5.0 or later** installed
2. **Python 3.8+** installed
3. **Git** installed
4. **ESP32 development board**
5. **USB cable** (must support data transfer)

## 🚀 Quick Start (5 Minutes)

### Step 1: Clone Repository

```bash
git clone https://github.com/devkiraa/DeZer0.git
cd DeZer0
```

### Step 2: Setup ESP-IDF Environment

**Windows (PowerShell):**
```powershell
# If ESP-IDF is installed at C:\esp\esp-idf
cd C:\esp\esp-idf
.\export.ps1
cd path\to\DeZer0
```

**Linux/macOS:**
```bash
# If ESP-IDF is installed at ~/esp/esp-idf
. $HOME/esp/esp-idf/export.sh
cd path/to/DeZer0
```

### Step 3: Build Firmware

### Step 3: Build Firmware

```bash
# Automated build (recommended)
python build_with_docker.py
```

This will:
- ✅ Check Docker installation
- ✅ Configure build for ESP32
- ✅ Compile all source files
- ✅ Generate .bin files
- ✅ Copy binaries to `firmware_bins/`
- ✅ Create flash helper scripts

**Build takes 5-10 minutes on first run** (incremental builds are faster)

### Step 4: Flash to ESP32

**Method A: Using Flash Script (Easiest)**

```bash
cd firmware_bins

# Windows PowerShell:
.\flash.ps1 COM3

# Linux/macOS:
./flash.sh /dev/ttyUSB0
```

**Method B: Using ESP-IDF**

```bash
cd firmware
idf.py -p COM3 flash monitor
```

**Method C: Manual with esptool**

```bash
cd firmware_bins
esptool.py --chip esp32 --port COM3 --baud 460800 write_flash -z \
  0x1000 bootloader.bin \
  0x8000 partition-table.bin \
  0x10000 dezero_firmware.bin
```

### Step 5: Verify Installation

After flashing, you should see:
- Device restarts automatically
- Display shows "DeZero v2.0"
- BLE advertising starts (device name: "DeZero")
- Serial output shows initialization messages

## 🔧 Development Workflow

### Incremental Builds (Faster)

After first build, use `--clean` to force clean build if needed, otherwise it's incremental by default in docker if volume persists, or use local build:

```bash
python build_with_docker.py
```

This skips the clean step and only recompiles changed files.

### Manual Build (Advanced)

```bash
cd firmware

# Configure (first time only)
idf.py set-target esp32

# Build
idf.py build

# Flash
idf.py -p COM3 flash

# Monitor serial output
idf.py -p COM3 monitor

# Or combine flash + monitor
idf.py -p COM3 flash monitor
```

### Customizing Configuration

```bash
cd firmware
idf.py menuconfig
```

This opens a configuration menu where you can:
- Change partition sizes
- Enable/disable features
- Configure WiFi/Bluetooth settings
- Adjust performance options

## 🛠️ Troubleshooting

### "ESP-IDF not found"

**Solution:** Install ESP-IDF v5.0+
```bash
# Follow official guide:
# https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/
```

### "Failed to connect to ESP32"

**Solutions:**
1. Hold BOOT button, press RESET, release BOOT
2. Check USB cable (must support data)
3. Try different USB port
4. Install CP210x or CH340 drivers
5. Check device manager for correct COM port

### "Partition table does not fit"

**Solution:** ESP32 needs 4MB flash minimum
```bash
# Check flash size:
esptool.py --port COM3 flash_id

# If less than 4MB, get a different ESP32 module
```

### Build Errors

**"Cannot find idf.py":**
- Run ESP-IDF export script first (see Step 2)

**"CMake version too old":**
- Install CMake 3.16 or later

**"Python module not found":**
```bash
pip install -r $IDF_PATH/requirements.txt
```

**Compile errors:**
```bash
# Clean and rebuild
cd firmware
idf.py fullclean
idf.py build
```

### Flash Errors

**"A fatal error occurred: Timed out":**
- Lower baud rate: `--baud 115200`
- Try holding BOOT during entire flash process

**"Hash of data verified" but device won't boot:**
- Erase flash completely first:
```bash
esptool.py --port COM3 erase_flash
# Then reflash
```

### Runtime Issues

**Display not working:**
- Check SSD1306 connections (SDA, SCL, VCC, GND)
- Verify I2C pins in `display_api.cpp` match your wiring
- Display is optional, firmware works without it

**BLE not advertising:**
- Check Bluetooth is enabled in menuconfig
- Restart device
- Check serial output for BLE initialization errors

**Device crashes/reboots:**
- Monitor serial output: `idf.py -p COM3 monitor`
- Check power supply (500mA minimum)
- Look for stack traces in logs

## 📊 Build Output

After successful build, `firmware_bins/` contains:

```
firmware_bins/
├── bootloader.bin         (~28 KB)  - ESP32 bootloader
├── partition-table.bin    (~3 KB)   - Partition layout
├── dezero_firmware.bin    (~1.2 MB) - Main application
├── flash.ps1              - Windows flash script
├── flash.sh               - Linux/macOS flash script
└── README.txt             - Flashing instructions
```

## 🎯 Next Steps

After successful flash:

1. **Install Mobile App**
   - Download from [DeZer0 Releases](https://github.com/devkiraa/DeZer0/releases)
   - Install APK on Android device

2. **Connect via BLE**
   - Open DeZero app
   - Go to Device screen
   - Scan and connect to "DeZero"

3. **Upload Payloads**
   - Browse marketplace in app
   - Download and install payloads
   - Execute and monitor output

4. **Create Custom Tools**
   - Install [Nex CLI](https://github.com/nexhq/nex): `iwr https://raw.githubusercontent.com/nexhq/nex/main/cli/install.ps1 | iex`
   - Create new package: `nex init`
   - Publish to registry: `nex publish`

## 📚 Additional Resources

- [Firmware Build Guide](firmware/BUILD_GUIDE.md) - Detailed build documentation
- [Payload Development](firmware/payloads/README.md) - Create custom payloads
- [API Reference](firmware/main/include/payload_api.h) - Payload API documentation
- [ESP-IDF Docs](https://docs.espressif.com/projects/esp-idf/) - ESP-IDF reference

## 💬 Need Help?

- [GitHub Issues](https://github.com/devkiraa/DeZer0/issues) - Report bugs
- [GitHub Discussions](https://github.com/devkiraa/DeZer0/discussions) - Ask questions
- Check serial monitor output for error messages
- Include full error logs when reporting issues

---

**Happy Hacking! 🚀**
