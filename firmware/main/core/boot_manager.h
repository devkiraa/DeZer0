#ifndef BOOT_MANAGER_H
#define BOOT_MANAGER_H

#include "esp_ota_ops.h"
#include "../include/types.h"

class BootManager {
public:
    static BootManager& getInstance() {
        static BootManager instance;
        return instance;
    }
    
    bool initialize();
    bool checkForUpdate();
    bool applyUpdate();
    const char* getFirmwareVersion();
    const esp_app_desc_t* getAppDescription();
    
private:
    BootManager() = default;
    ~BootManager() = default;
    BootManager(const BootManager&) = delete;
    BootManager& operator=(const BootManager&) = delete;
    
    bool validatePartition(const esp_partition_t* partition);
    
    const esp_partition_t* current_partition_;
    const esp_partition_t* update_partition_;
    esp_ota_handle_t ota_handle_;
    bool ota_in_progress_;
};

#endif // BOOT_MANAGER_H
