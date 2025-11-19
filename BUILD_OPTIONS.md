# Building DeZero Firmware - Options Comparison

## ⚡ Quick Decision Guide

**Want zero local setup?** → Use GitHub Actions (Option 3)  
**Have Docker?** → Use Docker builder (Option 2)  
**Are you a developer?** → Install ESP-IDF (Option 1)

---

## Option 1: ESP-IDF Installation (Original Method)

### What You Need:
- ESP-IDF v5.0+ installed
- CMake 3.16+
- Python 3.8+
- ~4GB disk space

### How to Build:
```bash
# Setup ESP-IDF environment
. $HOME/esp/esp-idf/export.sh   # Linux/macOS
# OR
. $env:IDF_PATH\export.ps1      # Windows PowerShell

# Build
python build_firmware.py
```

### ✅ Pros:
- Full control over build process
- Fastest rebuilds (incremental builds)
- Can customize ESP-IDF settings
- Best for active development

### ❌ Cons:
- Large installation (~4GB)
- Complex setup on Windows
- Need to maintain ESP-IDF version

---

## Option 2: Docker Builder (NEW - Recommended for Most Users)

### What You Need:
- Docker Desktop installed
- Python 3.8+
- Internet connection (first run only)

### How to Build:
```bash
# Install Docker Desktop from:
# https://www.docker.com/products/docker-desktop

# Build firmware (Docker handles everything!)
python build_with_docker.py

# Clean build
python build_with_docker.py --clean
```

### ✅ Pros:
- **NO ESP-IDF installation required!**
- Works identically on Windows/Linux/macOS
- Consistent build environment
- Easy to switch ESP-IDF versions
- Only ~500MB Docker image

### ❌ Cons:
- Requires Docker Desktop
- First build slower (downloads image ~3-5 min)
- Slightly slower than native ESP-IDF

### Docker Image Details:
- Image: `espressif/idf:v5.0`
- Size: ~500MB compressed
- Contains: ESP-IDF + all toolchains
- Auto-pulled on first run

---

## Option 3: GitHub Actions (Zero Local Setup)

### What You Need:
- GitHub account
- Push to GitHub repository

### How to Build:
```bash
# Method A: Automatic on push
git add firmware/
git commit -m "Update firmware"
git push

# Method B: Manual trigger
# Go to GitHub → Actions → Build ESP-IDF Firmware → Run workflow

# Method C: Create release
git tag v1.0.0
git push --tags
```

### Where to Download:
1. Go to repository → Actions
2. Click latest workflow run
3. Download "dezero-firmware-xxx" artifact
4. Extract and flash

### ✅ Pros:
- **ZERO local setup!**
- Builds in the cloud
- Perfect for beginners
- Automatic releases on tags
- Works from any device

### ❌ Cons:
- Requires internet
- 2-5 minutes build time
- Limited to 2000 minutes/month (free tier)
- Can't test locally without download

---

## Build Output (All Methods)

All methods produce identical files in `firmware_bins/`:

```
firmware_bins/
├── bootloader.bin           (~28 KB)  @ 0x1000
├── partition-table.bin      (~3 KB)   @ 0x8000
├── dezero_firmware.bin      (~1.2 MB) @ 0x10000
├── flash.ps1                (Windows flash script)
├── flash.sh                 (Linux/macOS flash script)
└── README.txt              (Instructions)
```

---

## Flashing After Build

### Method 1: Use Generated Scripts
```bash
cd firmware_bins

# Windows
.\flash.ps1

# Linux/macOS
./flash.sh
```

### Method 2: Manual Flash
```bash
pip install esptool

esptool.py -p COM3 -b 460800 write_flash \
  0x1000 bootloader.bin \
  0x8000 partition-table.bin \
  0x10000 dezero_firmware.bin
```

### Method 3: Web Flasher
1. Upload binaries to GitHub release (DeZer0-Tools repo)
2. Use web flasher at your deployment URL
3. Select release and flash

---

## Installation Guides

### Docker Desktop (for Option 2)

**Windows:**
1. Download: https://www.docker.com/products/docker-desktop
2. Install Docker Desktop
3. Restart computer
4. Run: `docker --version` to verify

**Linux:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Logout and login
docker --version
```

**macOS:**
1. Download: https://www.docker.com/products/docker-desktop
2. Install Docker.app
3. Run: `docker --version` to verify

### ESP-IDF (for Option 1)

**Windows:**
1. Download installer: https://dl.espressif.com/dl/esp-idf/
2. Run ESP-IDF installer
3. Install to: `C:\Espressif`
4. Use "ESP-IDF PowerShell" shortcut

**Linux:**
```bash
mkdir -p ~/esp
cd ~/esp
git clone --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
./install.sh esp32
. ./export.sh
```

**macOS:**
```bash
brew install cmake ninja dfu-util
mkdir -p ~/esp
cd ~/esp
git clone --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
./install.sh esp32
. ./export.sh
```

---

## Comparison Table

| Feature | ESP-IDF Native | Docker | GitHub Actions |
|---------|---------------|--------|----------------|
| Setup Time | 30-60 min | 5 min | 0 min |
| Disk Space | ~4 GB | ~500 MB | 0 |
| Build Speed | ⚡⚡⚡ Fast | ⚡⚡ Medium | ⚡ Slow |
| Internet | Setup only | First run | Every build |
| Platform | All | All | Any |
| Complexity | High | Low | None |
| Best For | Developers | Most users | Beginners |

---

## Recommended Choice

**First-time user / Beginner:**
→ **GitHub Actions** (Option 3) - Zero setup, just push code

**Regular user / Small team:**
→ **Docker** (Option 2) - Easy setup, consistent builds

**Active developer / Large codebase:**
→ **ESP-IDF Native** (Option 1) - Fastest, full control

---

## Troubleshooting

### Docker Builder Issues

**Error: "Cannot connect to Docker daemon"**
```bash
# Ensure Docker Desktop is running
# Windows: Check system tray for Docker icon
# Linux: sudo systemctl start docker
```

**Error: "Permission denied" (Linux)**
```bash
sudo usermod -aG docker $USER
# Logout and login again
```

**Build fails with "exec format error"**
```bash
# Wrong CPU architecture, use:
docker pull --platform linux/amd64 espressif/idf:v5.0
```

### GitHub Actions Issues

**Workflow doesn't trigger**
- Check Actions are enabled: Settings → Actions → General
- Ensure you pushed to `main` branch
- Check file paths match `firmware/**`

**Build fails**
- Check `firmware/CMakeLists.txt` exists
- Verify ESP-IDF version compatibility
- Check Actions logs for details

---

## FAQ

**Q: Which method produces the best binaries?**  
A: All methods produce identical binaries. Choose based on convenience.

**Q: Can I mix methods?**  
A: Yes! Use GitHub Actions for releases, Docker for local testing.

**Q: Do I need all three?**  
A: No! Pick ONE method that suits your workflow.

**Q: Will GitHub Actions cost money?**  
A: Free tier includes 2000 minutes/month. Each build takes ~5 min, so 400 builds/month free.

**Q: Can Docker run on Raspberry Pi?**  
A: Yes, but use ARM64 image: `espressif/idf:v5.0-arm64`

**Q: Is Docker secure?**  
A: Yes, Docker containers are isolated. Official Espressif images are safe.

---

## Next Steps

After building, you can:

1. **Flash to ESP32**
   - Use generated flash scripts
   - Or use web flasher

2. **Create Release**
   - Upload binaries to DeZer0-Tools repository
   - Tag with version (e.g., v1.0.0)
   - Web flasher will auto-detect

3. **Test Firmware**
   - Connect via serial monitor
   - Check boot logs
   - Test BLE/WiFi connectivity

4. **Develop Payloads**
   - See `firmware/payloads/README.md`
   - Build tools for DeZero
   - Publish to marketplace
