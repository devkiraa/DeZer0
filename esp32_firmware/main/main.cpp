#include <stdio.h>
#include <string.h>
#include <inttypes.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_log.h"
#include "nvs_flash.h"

#include "core/boot_manager.h"
#include "core/storage_manager.h"
#include "core/plugin_manager.h"
#include "hal/display_api.h"
#include "communication/ble_server.h"
#include "communication/wifi_manager.h"

static const char* TAG = "MAIN";

extern "C" void app_main(void) {
    ESP_LOGI(TAG, "DeZero Firmware v%s Starting...", DEZERO_VERSION);
    
    // Initialize NVS
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);
    
    // Initialize boot manager
    ESP_LOGI(TAG, "Initializing Boot Manager...");
    if (!BootManager::getInstance().initialize()) {
        ESP_LOGE(TAG, "Failed to initialize Boot Manager");
        esp_restart();
        return;
    }
    
    // Initialize storage manager
    ESP_LOGI(TAG, "Initializing Storage Manager...");
    if (!StorageManager::getInstance().initialize()) {
        ESP_LOGE(TAG, "Failed to initialize Storage Manager");
        esp_restart();
        return;
    }
    
    // Initialize display
    ESP_LOGI(TAG, "Initializing Display...");
    DisplayAPI::getInstance().initialize();
    DisplayAPI::getInstance().clear();
    DisplayAPI::getInstance().drawText(0, 0, "DeZero v2.0", 2);
    DisplayAPI::getInstance().drawText(0, 20, "Initializing...", 1);
    DisplayAPI::getInstance().update();
    
    // Initialize WiFi manager
    ESP_LOGI(TAG, "Initializing WiFi Manager...");
    WiFiManager::getInstance().initialize();
    
    // Initialize BLE server
    ESP_LOGI(TAG, "Initializing BLE Server...");
    BLEServer::getInstance().initialize();
    BLEServer::getInstance().start();
    
    // Initialize plugin manager
    ESP_LOGI(TAG, "Initializing Plugin Manager...");
    if (!PluginManager::getInstance().initialize()) {
        ESP_LOGE(TAG, "Failed to initialize Plugin Manager");
    } else {
        ESP_LOGI(TAG, "Plugin Manager initialized successfully");
        
        // Scan for payloads
        int payload_count = PluginManager::getInstance().scanPayloads();
        ESP_LOGI(TAG, "Found %d payloads", payload_count);
    }
    
    // Update display
    DisplayAPI::getInstance().clear();
    DisplayAPI::getInstance().drawText(0, 0, "DeZero v2.0", 2);
    DisplayAPI::getInstance().drawText(0, 20, "Ready", 1);
    DisplayAPI::getInstance().drawText(0, 40, "BLE: Active", 1);
    DisplayAPI::getInstance().update();
    
    ESP_LOGI(TAG, "System initialization complete");
    ESP_LOGI(TAG, "Free heap: %" PRIu32 " bytes", esp_get_free_heap_size());
    
    // Main loop
    while (true) {
        vTaskDelay(pdMS_TO_TICKS(1000));
        
        // Periodic tasks
        PluginManager::getInstance().update();
    }
}
