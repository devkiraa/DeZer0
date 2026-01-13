#include "boot_manager.h"
#include "esp_log.h"
#include "esp_system.h"
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char* TAG = "BootManager";

bool BootManager::initialize() {
    ESP_LOGI(TAG, "Initializing Boot Manager");
    
    // Get current running partition
    current_partition_ = esp_ota_get_running_partition();
    if (!current_partition_) {
        ESP_LOGE(TAG, "Failed to get current partition");
        return false;
    }
    
    ESP_LOGI(TAG, "Running from partition: %s at 0x%08lx", 
             current_partition_->label, current_partition_->address);
    
    // Get update partition
    update_partition_ = esp_ota_get_next_update_partition(NULL);
    if (!update_partition_) {
        ESP_LOGE(TAG, "Failed to get update partition");
        return false;
    }
    
    ESP_LOGI(TAG, "Update partition: %s at 0x%08lx", 
             update_partition_->label, update_partition_->address);
    
    // Print app description
    const esp_app_desc_t* app_desc = getAppDescription();
    if (app_desc) {
        ESP_LOGI(TAG, "Firmware version: %s", app_desc->version);
        ESP_LOGI(TAG, "Project name: %s", app_desc->project_name);
        ESP_LOGI(TAG, "Compile date: %s %s", app_desc->date, app_desc->time);
        ESP_LOGI(TAG, "IDF version: %s", app_desc->idf_ver);
    }
    
    ota_in_progress_ = false;
    
    return true;
}

bool BootManager::checkForUpdate() {
    // Check if update partition has valid app
    esp_app_desc_t update_desc;
    if (esp_ota_get_partition_description(update_partition_, &update_desc) == ESP_OK) {
        ESP_LOGI(TAG, "Update partition has firmware version: %s", update_desc.version);
        
        // Compare versions
        const esp_app_desc_t* current_desc = getAppDescription();
        if (current_desc && strcmp(current_desc->version, update_desc.version) != 0) {
            ESP_LOGI(TAG, "Update available: %s -> %s", 
                     current_desc->version, update_desc.version);
            return true;
        }
    }
    
    return false;
}

bool BootManager::applyUpdate() {
    if (!update_partition_) {
        ESP_LOGE(TAG, "No update partition available");
        return false;
    }
    
    // Validate update partition
    if (!validatePartition(update_partition_)) {
        ESP_LOGE(TAG, "Update partition validation failed");
        return false;
    }
    
    // Set boot partition
    esp_err_t err = esp_ota_set_boot_partition(update_partition_);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to set boot partition: %s", esp_err_to_name(err));
        return false;
    }
    
    ESP_LOGI(TAG, "Update applied successfully. Restarting...");
    vTaskDelay(pdMS_TO_TICKS(1000));
    esp_restart();
    
    return true;
}

const char* BootManager::getFirmwareVersion() {
    const esp_app_desc_t* desc = getAppDescription();
    return desc ? desc->version : "Unknown";
}

const esp_app_desc_t* BootManager::getAppDescription() {
    return esp_app_get_description();
}

bool BootManager::validatePartition(const esp_partition_t* partition) {
    if (!partition) {
        return false;
    }
    
    // Read app description from partition
    esp_app_desc_t app_desc;
    esp_err_t err = esp_ota_get_partition_description(partition, &app_desc);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "Failed to get partition description: %s", esp_err_to_name(err));
        return false;
    }
    
    // Validate magic byte
    if (app_desc.magic_word != ESP_APP_DESC_MAGIC_WORD) {
        ESP_LOGE(TAG, "Invalid magic word in partition");
        return false;
    }
    
    ESP_LOGI(TAG, "Partition validation successful");
    return true;
}
