#include "wifi_scanner.h"
#include "../hal/wifi_api.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char* TAG = "WiFiScanner";

bool WiFiScanner::execute(const std::map<std::string, std::string>& params) {
    ESP_LOGI(TAG, "Executing WiFi Scanner built-in module");
    
    auto& wifi = WiFiAPI::getInstance();
    
    if (!wifi.startScan()) {
        ESP_LOGE(TAG, "Failed to start WiFi scan");
        return false;
    }
    
    vTaskDelay(pdMS_TO_TICKS(3000));
    
    auto results = wifi.getScanResults();
    ESP_LOGI(TAG, "Found %d WiFi networks", (int)results.size());
    
    for (const auto& ap : results) {
        ESP_LOGI(TAG, "SSID: %s, RSSI: %d, Channel: %d",
                 (char*)ap.ssid, ap.rssi, ap.primary);
    }
    
    return true;
}
