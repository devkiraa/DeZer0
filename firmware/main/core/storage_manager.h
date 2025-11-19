#ifndef STORAGE_MANAGER_H
#define STORAGE_MANAGER_H

#include <string>
#include <vector>
#include "esp_spiffs.h"
#include "../include/types.h"

class StorageManager {
public:
    static StorageManager& getInstance() {
        static StorageManager instance;
        return instance;
    }
    
    bool initialize();
    void deinit();
    
    // File operations
    bool fileExists(const char* path);
    int readFile(const char* path, uint8_t* buffer, size_t max_size);
    bool writeFile(const char* path, const uint8_t* data, size_t size);
    bool deleteFile(const char* path);
    size_t getFileSize(const char* path);
    
    // Directory operations
    bool createDirectory(const char* path);
    bool deleteDirectory(const char* path);
    std::vector<std::string> listDirectory(const char* path);
    
    // Storage info
    size_t getTotalSpace();
    size_t getUsedSpace();
    size_t getFreeSpace();
    
    // Payload-specific paths
    std::string getPayloadPath(const char* payload_id);
    std::string getPayloadManifestPath(const char* payload_id);
    std::string getPayloadDataPath(const char* payload_id);
    
private:
    StorageManager() = default;
    ~StorageManager() = default;
    StorageManager(const StorageManager&) = delete;
    StorageManager& operator=(const StorageManager&) = delete;
    
    bool mounted_;
    size_t total_bytes_;
    size_t used_bytes_;
};

#endif // STORAGE_MANAGER_H
