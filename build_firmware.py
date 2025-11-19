#!/usr/bin/env python3
"""
DeZero Firmware Builder
Builds ESP-IDF firmware and generates .bin files for flashing
"""

import os
import sys
import subprocess
import shutil
import platform
from pathlib import Path

class FirmwareBuilder:
    def __init__(self):
        self.script_dir = Path(__file__).parent
        self.firmware_dir = self.script_dir / "firmware"
        self.build_dir = self.firmware_dir / "build"
        self.output_dir = self.script_dir / "firmware_bins"
        
    def check_esp_idf(self):
        """Check if ESP-IDF is available in environment"""
        print("🔍 Checking ESP-IDF installation...")
        
        try:
            result = subprocess.run(
                ["idf.py", "--version"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                version = result.stdout.strip()
                print(f"✅ ESP-IDF found: {version}")
                return True
            else:
                print("❌ ESP-IDF not found in PATH")
                return False
                
        except (subprocess.TimeoutExpired, FileNotFoundError):
            print("❌ ESP-IDF not found. Please install ESP-IDF v5.0+ and run:")
            if platform.system() == "Windows":
                print("   PowerShell: . $env:IDF_PATH\\export.ps1")
                print("   CMD: %IDF_PATH%\\export.bat")
            else:
                print("   . $HOME/esp/esp-idf/export.sh")
            return False
    
    def clean_build(self):
        """Clean previous build artifacts"""
        print("\n🧹 Cleaning previous build...")
        
        if self.build_dir.exists():
            try:
                shutil.rmtree(self.build_dir)
                print("✅ Build directory cleaned")
            except Exception as e:
                print(f"⚠️  Warning: Could not clean build directory: {e}")
        
        # Also clean sdkconfig if it exists (force defaults)
        sdkconfig = self.firmware_dir / "sdkconfig"
        if sdkconfig.exists():
            try:
                sdkconfig.unlink()
                print("✅ sdkconfig removed (will use defaults)")
            except Exception as e:
                print(f"⚠️  Warning: Could not remove sdkconfig: {e}")
    
    def set_target(self):
        """Set ESP32 as build target"""
        print("\n🎯 Setting target to ESP32...")
        
        try:
            result = subprocess.run(
                ["idf.py", "set-target", "esp32"],
                cwd=self.firmware_dir,
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode == 0:
                print("✅ Target set to ESP32")
                return True
            else:
                print(f"❌ Failed to set target:\n{result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            print("❌ Timeout while setting target")
            return False
        except Exception as e:
            print(f"❌ Error setting target: {e}")
            return False
    
    def build_firmware(self):
        """Build the firmware"""
        print("\n🔨 Building firmware...")
        print("This may take several minutes on first build...")
        
        try:
            # Run build with output streaming
            process = subprocess.Popen(
                ["idf.py", "build"],
                cwd=self.firmware_dir,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # Print output in real-time
            for line in process.stdout:
                print(line, end='')
            
            process.wait()
            
            if process.returncode == 0:
                print("\n✅ Firmware built successfully!")
                return True
            else:
                print(f"\n❌ Build failed with exit code {process.returncode}")
                return False
                
        except Exception as e:
            print(f"\n❌ Build error: {e}")
            return False
    
    def copy_binaries(self):
        """Copy generated binaries to output directory"""
        print("\n📦 Copying binary files...")
        
        # Create output directory
        self.output_dir.mkdir(exist_ok=True)
        
        # Files to copy
        bin_files = {
            "bootloader/bootloader.bin": "bootloader.bin",
            "partition_table/partition-table.bin": "partition-table.bin",
            "dezero_firmware.bin": "dezero_firmware.bin",
        }
        
        copied = 0
        for src_file, dst_file in bin_files.items():
            src_path = self.build_dir / src_file
            dst_path = self.output_dir / dst_file
            
            if src_path.exists():
                try:
                    shutil.copy2(src_path, dst_path)
                    size = dst_path.stat().st_size
                    print(f"✅ Copied {dst_file} ({size:,} bytes)")
                    copied += 1
                except Exception as e:
                    print(f"⚠️  Warning: Could not copy {dst_file}: {e}")
            else:
                print(f"⚠️  Warning: {src_file} not found")
        
        if copied == len(bin_files):
            print(f"\n✅ All {copied} binary files copied to: {self.output_dir}")
            return True
        else:
            print(f"\n⚠️  Only {copied}/{len(bin_files)} files copied")
            return False
    
    def create_flash_script(self):
        """Create helper scripts for flashing"""
        print("\n📝 Creating flash helper scripts...")
        
        # Windows PowerShell script
        ps_script = self.output_dir / "flash.ps1"
        ps_content = """# DeZero Firmware Flash Script (PowerShell)
# Usage: .\\flash.ps1 COM3

param(
    [Parameter(Mandatory=$true)]
    [string]$Port
)

Write-Host "Flashing DeZero Firmware to $Port..." -ForegroundColor Cyan

$bootloaderOffset = "0x1000"
$partitionOffset = "0x8000"
$appOffset = "0x10000"

esptool.py --chip esp32 --port $Port --baud 460800 `
    write_flash -z `
    $bootloaderOffset bootloader.bin `
    $partitionOffset partition-table.bin `
    $appOffset dezero_firmware.bin

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nFlashing completed successfully!" -ForegroundColor Green
    Write-Host "You can now monitor the device with: idf.py -p $Port monitor" -ForegroundColor Yellow
} else {
    Write-Host "`nFlashing failed!" -ForegroundColor Red
}
"""
        
        # Bash script
        sh_script = self.output_dir / "flash.sh"
        sh_content = """#!/bin/bash
# DeZero Firmware Flash Script
# Usage: ./flash.sh /dev/ttyUSB0

if [ -z "$1" ]; then
    echo "Usage: $0 <port>"
    echo "Example: $0 /dev/ttyUSB0"
    exit 1
fi

PORT=$1

echo "Flashing DeZero Firmware to $PORT..."

esptool.py --chip esp32 --port $PORT --baud 460800 \\
    write_flash -z \\
    0x1000 bootloader.bin \\
    0x8000 partition-table.bin \\
    0x10000 dezero_firmware.bin

if [ $? -eq 0 ]; then
    echo ""
    echo "Flashing completed successfully!"
    echo "You can now monitor the device with: idf.py -p $PORT monitor"
else
    echo ""
    echo "Flashing failed!"
    exit 1
fi
"""
        
        try:
            # Write PowerShell script
            ps_script.write_text(ps_content, encoding='utf-8')
            print(f"✅ Created {ps_script.name}")
            
            # Write bash script
            sh_script.write_text(sh_content, encoding='utf-8')
            if platform.system() != "Windows":
                os.chmod(sh_script, 0o755)
            print(f"✅ Created {sh_script.name}")
            
            return True
        except Exception as e:
            print(f"⚠️  Warning: Could not create flash scripts: {e}")
            return False
    
    def create_readme(self):
        """Create README with flashing instructions"""
        readme = self.output_dir / "README.txt"
        content = """DeZero Firmware v2.0 - Binary Files
=====================================

This directory contains the compiled firmware binaries ready for flashing.

FILES:
------
- bootloader.bin         : ESP32 bootloader
- partition-table.bin    : Flash partition table
- dezero_firmware.bin    : Main application firmware

FLASHING INSTRUCTIONS:
----------------------

Method 1: Using esptool.py (Recommended)
-----------------------------------------
Windows PowerShell:
  .\\flash.ps1 COM3

Linux/macOS:
  ./flash.sh /dev/ttyUSB0

Method 2: Using ESP-IDF
-----------------------
cd ../firmware
idf.py -p COM3 flash

Method 3: Manual with esptool.py
---------------------------------
esptool.py --chip esp32 --port COM3 --baud 460800 write_flash -z ^
  0x1000 bootloader.bin ^
  0x8000 partition-table.bin ^
  0x10000 dezero_firmware.bin

FIRST TIME SETUP:
-----------------
If flashing fails or device doesn't boot, erase flash first:
  esptool.py --chip esp32 --port COM3 erase_flash

Then flash again using one of the methods above.

MONITORING:
-----------
To view serial output:
  idf.py -p COM3 monitor

Or use any serial terminal at 115200 baud.

TROUBLESHOOTING:
----------------
- Hold BOOT button while connecting USB if flash fails
- Check correct COM port (Windows) or /dev/tty* (Linux/macOS)
- Ensure USB cable supports data (not charge-only)
- Try lower baud rate: --baud 115200

For more information:
https://github.com/devkiraa/DeZer0
"""
        
        try:
            readme.write_text(content, encoding='utf-8')
            print(f"✅ Created {readme.name}")
            return True
        except Exception as e:
            print(f"⚠️  Warning: Could not create README: {e}")
            return False
    
    def build(self, clean=True):
        """Main build process"""
        print("=" * 60)
        print("DeZero Firmware Builder v2.0")
        print("=" * 60)
        
        # Check ESP-IDF
        if not self.check_esp_idf():
            print("\n❌ Build aborted: ESP-IDF not found")
            return False
        
        # Clean if requested
        if clean:
            self.clean_build()
        
        # Set target
        if not self.set_target():
            print("\n❌ Build aborted: Could not set target")
            return False
        
        # Build firmware
        if not self.build_firmware():
            print("\n❌ Build aborted: Compilation failed")
            return False
        
        # Copy binaries
        if not self.copy_binaries():
            print("\n⚠️  Warning: Some files were not copied")
        
        # Create helper scripts
        self.create_flash_script()
        self.create_readme()
        
        print("\n" + "=" * 60)
        print("✅ BUILD COMPLETE!")
        print("=" * 60)
        print(f"\nBinary files location: {self.output_dir.absolute()}")
        print("\nNext steps:")
        print("1. Connect ESP32 via USB")
        print("2. Run flash script:")
        if platform.system() == "Windows":
            print(f"   cd {self.output_dir.absolute()}")
            print("   .\\flash.ps1 COM3  (replace COM3 with your port)")
        else:
            print(f"   cd {self.output_dir.absolute()}")
            print("   ./flash.sh /dev/ttyUSB0  (replace with your port)")
        print("\n")
        
        return True


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Build DeZero ESP32 firmware",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python build_firmware.py              # Full clean build
  python build_firmware.py --no-clean   # Incremental build
        """
    )
    
    parser.add_argument(
        "--no-clean",
        action="store_true",
        help="Skip cleaning build directory (faster incremental builds)"
    )
    
    args = parser.parse_args()
    
    builder = FirmwareBuilder()
    success = builder.build(clean=not args.no_clean)
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
