import os
from littlefs import LittleFS

# Configure the filesystem
fs = LittleFS(block_size=4096, block_count=256)

# Source directory for the files
source_dir = "ESP"

# Walk through the source directory and add files to the filesystem
for root, dirs, files in os.walk(source_dir):
    for file in files:
        source_path = os.path.join(root, file)
        dest_path = os.path.relpath(source_path, source_dir)

        # Create directories in the filesystem
        if os.path.dirname(dest_path):
            fs.makedirs(os.path.dirname(dest_path), exist_ok=True)

        with open(source_path, "rb") as f:
            with fs.open(dest_path, "wb") as fs_file:
                fs_file.write(f.read())

# Write the filesystem to a file
with open("web_flasher/public/filesystem.bin", "wb") as fh:
    fh.write(fs.context.buffer)

print("Filesystem image created successfully at web_flasher/public/filesystem.bin")
