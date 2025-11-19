#!/usr/bin/env python3
"""
DeZero Docker Firmware Builder
Build ESP-IDF firmware using Docker - NO ESP-IDF installation required!
Only requires: Python 3.8+ and Docker Desktop
"""

import os
import sys
import subprocess
import shutil
import platform
from pathlib import Path

class DockerFirmwareBuilder:
    def __init__(self):
        self.script_dir = Path(__file__).parent
        self.firmware_dir = self.script_dir / "firmware"
        self.output_dir = self.script_dir / "firmware_bins"
        self.docker_image = "espressif/idf:v5.0"
        
    def check_docker(self):
        """Check if Docker is available"""
        print("🔍 Checking Docker installation...")
        
        try:
            result = subprocess.run(
                ["docker", "--version"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                version = result.stdout.strip()
                print(f"✅ Docker found: {version}")
                return True
            else:
                print("❌ Docker not found")
                return False
                
        except (subprocess.TimeoutExpired, FileNotFoundError):
            print("❌ Docker not found. Please install Docker Desktop:")
            print("   https://www.docker.com/products/docker-desktop")
            return False
    
    def pull_docker_image(self):
        """Pull ESP-IDF Docker image"""
        print(f"\n📦 Pulling ESP-IDF Docker image: {self.docker_image}")
        print("   (This may take a few minutes on first run)")
        
        try:
            result = subprocess.run(
                ["docker", "pull", self.docker_image],
                timeout=600  # 10 minutes
            )
            
            if result.returncode == 0:
                print(f"✅ Docker image ready")
                return True
            else:
                print(f"❌ Failed to pull Docker image")
                return False
                
        except subprocess.TimeoutExpired:
            print("❌ Docker pull timed out")
            return False
    
    def build_in_docker(self):
        """Build firmware inside Docker container"""
        print("\n🔨 Building firmware in Docker container...")
        
        # Convert Windows paths for Docker
        if platform.system() == "Windows":
            # Convert D:\Repository\DeZer0 to /d/Repository/DeZer0
            firmware_path = str(self.firmware_dir).replace("\\", "/")
            if firmware_path[1] == ":":
                firmware_path = f"/{firmware_path[0].lower()}{firmware_path[2:]}"
        else:
            firmware_path = str(self.firmware_dir.absolute())
        
        # Docker run command
        docker_cmd = [
            "docker", "run", "--rm",
            "-v", f"{firmware_path}:/project",
            "-w", "/project",
            self.docker_image,
            "idf.py", "build"
        ]
        
        print(f"   Running: {' '.join(docker_cmd)}")
        
        try:
            result = subprocess.run(
                docker_cmd,
                timeout=600  # 10 minutes for build
            )
            
            if result.returncode == 0:
                print("✅ Build successful!")
                return True
            else:
                print("❌ Build failed")
                return False
                
        except subprocess.TimeoutExpired:
            print("❌ Build timed out")
            return False
    
    def organize_binaries(self):
        """Copy built binaries to output directory"""
        print("\n📦 Organizing binaries...")
        
        build_dir = self.firmware_dir / "build"
        
        if not build_dir.exists():
            print("❌ Build directory not found")
            return False
        
        # Create output directory
        self.output_dir.mkdir(exist_ok=True)
        
        # Files to copy and their locations
        files_to_copy = [
            ("bootloader/bootloader.bin", "bootloader.bin", 0x1000),
            ("partition_table/partition-table.bin", "partition-table.bin", 0x8000),
            ("ota_data_initial.bin", "ota_data_initial.bin", 0xd000),
            ("dezero_firmware.bin", "dezero_firmware.bin", 0x10000),
        ]
        
        copied_files = []
        for src_file, dest_file, address in files_to_copy:
            src_path = build_dir / src_file
            dest_path = self.output_dir / dest_file
            
            if src_path.exists():
                shutil.copy2(src_path, dest_path)
                size_kb = dest_path.stat().st_size / 1024
                print(f"   ✓ {dest_file} ({size_kb:.1f} KB) @ 0x{address:X}")
                copied_files.append((dest_file, address))
            else:
                print(f"   ⚠ {src_file} not found, skipping")
        
        if not copied_files:
            print("❌ No binaries found")
            return False
        
        # Generate flash scripts
        self.generate_flash_scripts(copied_files)
        
        # Create README
        self.create_readme()
        
        print(f"\n✅ Binaries ready in: {self.output_dir}")
        return True
    
    def generate_flash_scripts(self, files):
        """Generate flash helper scripts"""
        
        # PowerShell script for Windows
        ps_script = self.output_dir / "flash.ps1"
        with open(ps_script, 'w') as f:
            f.write("# DeZero Firmware Flash Script (PowerShell)\n")
            f.write("# Requires: esptool.py (pip install esptool)\n\n")
            
            flash_cmd = "esptool.py -p COM3 -b 460800 --before default_reset --after hard_reset write_flash --flash_mode dio --flash_freq 40m --flash_size 4MB"
            
            for filename, address in files:
                flash_cmd += f" 0x{address:X} {filename}"
            
            f.write(f"{flash_cmd}\n")
        
        # Bash script for Linux/macOS
        sh_script = self.output_dir / "flash.sh"
        with open(sh_script, 'w') as f:
            f.write("#!/bin/bash\n")
            f.write("# DeZero Firmware Flash Script\n")
            f.write("# Requires: esptool.py (pip install esptool)\n\n")
            
            flash_cmd = "esptool.py -p /dev/ttyUSB0 -b 460800 --before default_reset --after hard_reset write_flash --flash_mode dio --flash_freq 40m --flash_size 4MB"
            
            for filename, address in files:
                flash_cmd += f" 0x{address:X} {filename}"
            
            f.write(f"{flash_cmd}\n")
        
        # Make shell script executable on Unix
        if platform.system() != "Windows":
            os.chmod(sh_script, 0o755)
        
        print(f"   ✓ flash.ps1 (Windows)")
        print(f"   ✓ flash.sh (Linux/macOS)")
    
    def create_readme(self):
        """Create README in output directory"""
        readme = self.output_dir / "README.txt"
        with open(readme, 'w') as f:
            f.write("DeZero Firmware Binaries\n")
            f.write("=" * 50 + "\n\n")
            f.write("Flash these binaries to your ESP32:\n\n")
            f.write("METHOD 1: Use Flash Scripts\n")
            f.write("  Windows: .\\flash.ps1\n")
            f.write("  Linux/macOS: ./flash.sh\n\n")
            f.write("METHOD 2: Manual Flash\n")
            f.write("  esptool.py -p PORT -b 460800 write_flash \\\n")
            f.write("    0x1000 bootloader.bin \\\n")
            f.write("    0x8000 partition-table.bin \\\n")
            f.write("    0x10000 dezero_firmware.bin\n\n")
            f.write("METHOD 3: Web Flasher\n")
            f.write("  Upload these files to your GitHub release and use\n")
            f.write("  the web flasher at your deployment URL\n\n")
            f.write("Note: Replace PORT with your ESP32 serial port\n")
            f.write("  Windows: COM3, COM4, etc.\n")
            f.write("  Linux: /dev/ttyUSB0, /dev/ttyACM0\n")
            f.write("  macOS: /dev/cu.usbserial-*\n")
        
        print(f"   ✓ README.txt")
    
    def clean_build(self):
        """Clean previous build"""
        build_dir = self.firmware_dir / "build"
        if build_dir.exists():
            print("🧹 Cleaning previous build...")
            shutil.rmtree(build_dir)
            print("   ✓ Build directory cleaned")
    
    def create_release_package(self):
        """Create versioned release package and cleanup"""
        print("\n" + "=" * 60)
        print("📦 RELEASE PACKAGING")
        print("=" * 60)
        
        # Ask for version
        while True:
            version = input("Enter release version (e.g., v1.0.0): ").strip()
            if version:
                break
            print("❌ Version cannot be empty")
            
        # Create release directory
        release_dir = self.script_dir / version
        if release_dir.exists():
            print(f"⚠ Directory {version} already exists. Overwriting...")
            shutil.rmtree(release_dir)
        release_dir.mkdir()
        
        print(f"\n📦 Packaging release {version}...")
        
        # Copy essential files
        release_files = [
            "bootloader.bin",
            "partition-table.bin",
            "ota_data_initial.bin",
            "dezero_firmware.bin"
        ]
        
        success = True
        for filename in release_files:
            src = self.output_dir / filename
            dst = release_dir / filename
            if src.exists():
                shutil.copy2(src, dst)
                print(f"   ✓ {filename}")
            else:
                print(f"   ❌ {filename} missing!")
                success = False
        
        if not success:
            print("\n❌ Failed to package all files")
            return False

        # Update .gitignore
        gitignore_path = self.script_dir / ".gitignore"
        ignore_entries = [
            "firmware/build/",
            "firmware_bins/",
            "managed_components/",
            "dependencies.lock",
            "__pycache__/",
            "*.pyc"
        ]
        
        existing_ignores = set()
        if gitignore_path.exists():
            with open(gitignore_path, "r") as f:
                existing_ignores = set(line.strip() for line in f if line.strip())
        
        with open(gitignore_path, "a") as f:
            if not existing_ignores:
                f.write("# DeZero Build Artifacts\n")
            
            added = False
            for entry in ignore_entries:
                if entry not in existing_ignores:
                    if not added and existing_ignores:
                        f.write("\n# Build Artifacts\n")
                    f.write(f"{entry}\n")
                    added = True
            
            if added:
                print("   ✓ Updated .gitignore")

        # Cleanup
        print("\n🧹 Cleaning up build artifacts...")
        build_dir = self.firmware_dir / "build"
        if build_dir.exists():
            try:
                shutil.rmtree(build_dir)
                print("   ✓ Removed firmware/build")
            except Exception as e:
                print(f"   ⚠ Failed to remove build dir: {e}")
            
        if self.output_dir.exists():
            try:
                shutil.rmtree(self.output_dir)
                print("   ✓ Removed temporary bins")
            except Exception as e:
                print(f"   ⚠ Failed to remove temp bins: {e}")
            
        print(f"\n✅ Release {version} ready in: {release_dir}")
        return True

    def run(self, clean=False):
        """Main build process"""
        print("=" * 60)
        print("DeZero Docker Firmware Builder")
        print("=" * 60)
        
        # Check Docker
        if not self.check_docker():
            print("\n⚠ Please install Docker Desktop and try again")
            return 1
        
        # Pull Docker image
        if not self.pull_docker_image():
            print("\n❌ Failed to prepare Docker image")
            return 1
        
        # Clean if requested
        if clean:
            self.clean_build()
        
        # Build firmware
        if not self.build_in_docker():
            print("\n❌ Build failed")
            return 2
        
        # Organize binaries
        if not self.organize_binaries():
            print("\n❌ Failed to organize binaries")
            return 2
            
        # Create release package
        if not self.create_release_package():
            return 3
        
        print("\n" + "=" * 60)
        print("✅ BUILD & PACKAGE COMPLETE!")
        print("=" * 60)
        
        return 0

def main():
    """Entry point"""
    builder = DockerFirmwareBuilder()
    
    # Parse arguments
    clean = "--clean" in sys.argv or "-c" in sys.argv
    
    if "--help" in sys.argv or "-h" in sys.argv:
        print("DeZero Docker Firmware Builder")
        print("\nUsage:")
        print("  python build_with_docker.py [OPTIONS]")
        print("\nOptions:")
        print("  --clean, -c    Clean build directory before building")
        print("  --help, -h     Show this help message")
        print("\nRequirements:")
        print("  - Docker Desktop installed")
        print("  - Internet connection (first run only)")
        return 0
    
    return builder.run(clean=clean)

if __name__ == "__main__":
    sys.exit(main())
