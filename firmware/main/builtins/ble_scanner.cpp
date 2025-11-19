#include "ble_scanner.h"
#include "../hal/ble_api.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char* TAG = "BLEScanner";

bool BLEScanner::execute(const std::map<std::string, std::string>& params) {
    ESP_LOGI(TAG, "Executing BLE Scanner built-in module");
    
    auto& ble = BLEAPI::getInstance();
    
    if (!ble.startScan(5000)) {
        ESP_LOGE(TAG, "Failed to start BLE scan");
        return false;
    }
    
    vTaskDelay(pdMS_TO_TICKS(5000));
    
    auto results = ble.getScanResults();
    ESP_LOGI(TAG, "Found %d BLE devices", (int)results.size());
    
    for (const auto& device : results) {
        ESP_LOGI(TAG, "Device: %s, RSSI: %d", device.name.c_str(), device.rssi);
    }
    
    ble.stopScan();
    
    return true;
}
