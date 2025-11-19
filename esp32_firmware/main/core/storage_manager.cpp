#include "storage_manager.h"
#include "esp_log.h"
#include <sys/stat.h>
#include <dirent.h>
#include <stdio.h>
#include <string.h>

static const char* TAG = "StorageManager";
static const char* BASE_PATH = "/spiffs";

bool StorageManager::initialize() {
    ESP_LOGI(TAG, "Initializing SPIFFS storage");
    
    esp_vfs_spiffs_conf_t conf = {
        .base_path = BASE_PATH,
        .partition_label = "storage",
        .max_files = 10,
        .format_if_mount_failed = true
    };
    
    esp_err_t ret = esp_vfs_spiffs_register(&conf);
    
    if (ret != ESP_OK) {
        if (ret == ESP_FAIL) {
            ESP_LOGE(TAG, "Failed to mount or format filesystem");
        } else if (ret == ESP_ERR_NOT_FOUND) {
            ESP_LOGE(TAG, "Failed to find SPIFFS partition");
        } else {
            ESP_LOGE(TAG, "Failed to initialize SPIFFS: %s", esp_err_to_name(ret));
        }
        return false;
    }
    
    // Get partition info
    size_t total = 0, used = 0;
    ret = esp_spiffs_info("storage", &total, &used);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to get SPIFFS partition info: %s", esp_err_to_name(ret));
    } else {
        total_bytes_ = total;
        used_bytes_ = used;
        ESP_LOGI(TAG, "SPIFFS: Total=%d bytes, Used=%d bytes, Free=%d bytes", 
                 total, used, total - used);
    }
    
    // Create payloads directory if it doesn't exist
    createDirectory(PAYLOAD_BASE_PATH);
    
    mounted_ = true;
    return true;
}

void StorageManager::deinit() {
    if (mounted_) {
        esp_vfs_spiffs_unregister("storage");
        mounted_ = false;
    }
}

bool StorageManager::fileExists(const char* path) {
    struct stat st;
    return (stat(path, &st) == 0);
}

int StorageManager::readFile(const char* path, uint8_t* buffer, size_t max_size) {
    FILE* f = fopen(path, "rb");
    if (!f) {
        ESP_LOGE(TAG, "Failed to open file for reading: %s", path);
        return -1;
    }
    
    size_t bytes_read = fread(buffer, 1, max_size, f);
    fclose(f);
    
    return bytes_read;
}

bool StorageManager::writeFile(const char* path, const uint8_t* data, size_t size) {
    FILE* f = fopen(path, "wb");
    if (!f) {
        ESP_LOGE(TAG, "Failed to open file for writing: %s", path);
        return false;
    }
    
    size_t bytes_written = fwrite(data, 1, size, f);
    fclose(f);
    
    if (bytes_written != size) {
        ESP_LOGE(TAG, "Write incomplete: %d of %d bytes", bytes_written, size);
        return false;
    }
    
    return true;
}

bool StorageManager::deleteFile(const char* path) {
    if (unlink(path) != 0) {
        ESP_LOGE(TAG, "Failed to delete file: %s", path);
        return false;
    }
    return true;
}

size_t StorageManager::getFileSize(const char* path) {
    struct stat st;
    if (stat(path, &st) != 0) {
        return 0;
    }
    return st.st_size;
}

bool StorageManager::createDirectory(const char* path) {
    struct stat st;
    if (stat(path, &st) == 0) {
        return true; // Already exists
    }
    
    if (mkdir(path, 0755) != 0) {
        ESP_LOGE(TAG, "Failed to create directory: %s", path);
        return false;
    }
    
    return true;
}

bool StorageManager::deleteDirectory(const char* path) {
    // Delete all files in directory first
    auto files = listDirectory(path);
    for (const auto& file : files) {
        std::string full_path = std::string(path) + "/" + file;
        deleteFile(full_path.c_str());
    }
    
    if (rmdir(path) != 0) {
        ESP_LOGE(TAG, "Failed to delete directory: %s", path);
        return false;
    }
    
    return true;
}

std::vector<std::string> StorageManager::listDirectory(const char* path) {
    std::vector<std::string> files;
    
    DIR* dir = opendir(path);
    if (!dir) {
        ESP_LOGE(TAG, "Failed to open directory: %s", path);
        return files;
    }
    
    struct dirent* entry;
    while ((entry = readdir(dir)) != NULL) {
        // Skip . and ..
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }
        files.push_back(entry->d_name);
    }
    
    closedir(dir);
    return files;
}

size_t StorageManager::getTotalSpace() {
    size_t total = 0, used = 0;
    esp_spiffs_info("storage", &total, &used);
    return total;
}

size_t StorageManager::getUsedSpace() {
    size_t total = 0, used = 0;
    esp_spiffs_info("storage", &total, &used);
    return used;
}

size_t StorageManager::getFreeSpace() {
    return getTotalSpace() - getUsedSpace();
}

std::string StorageManager::getPayloadPath(const char* payload_id) {
    return std::string(PAYLOAD_BASE_PATH) + "/" + payload_id;
}

std::string StorageManager::getPayloadManifestPath(const char* payload_id) {
    return getPayloadPath(payload_id) + "/manifest.json";
}

std::string StorageManager::getPayloadDataPath(const char* payload_id) {
    return getPayloadPath(payload_id) + "/payload";
}
