#include "wifi_api.h"
#include "esp_log.h"
#include "esp_event.h"
#include <cstring>

static const char* TAG = "WiFiAPI";

bool WiFiAPI::initialize() {
    ESP_LOGI(TAG, "Initializing WiFi API");
    
    esp_netif_create_default_wifi_sta();
    
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_start());
    
    initialized_ = true;
    connected_ = false;
    
    return true;
}

bool WiFiAPI::startScan() {
    if (!initialized_) return false;
    
    wifi_scan_config_t scan_config = {};
    scan_config.show_hidden = true;
    
    esp_err_t err = esp_wifi_scan_start(&scan_config, true);
    return (err == ESP_OK);
}

std::vector<wifi_ap_record_t> WiFiAPI::getScanResults() {
    std::vector<wifi_ap_record_t> results;
    
    uint16_t ap_count = 0;
    esp_wifi_scan_get_ap_num(&ap_count);
    
    if (ap_count > 0) {
        wifi_ap_record_t* ap_records = new wifi_ap_record_t[ap_count];
        esp_wifi_scan_get_ap_records(&ap_count, ap_records);
        
        for (int i = 0; i < ap_count; i++) {
            results.push_back(ap_records[i]);
        }
        
        delete[] ap_records;
    }
    
    return results;
}

bool WiFiAPI::connect(const char* ssid, const char* password) {
    wifi_config_t wifi_config = {};
    strcpy((char*)wifi_config.sta.ssid, ssid);
    strcpy((char*)wifi_config.sta.password, password);
    
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_connect());
    
    connected_ = true;
    return true;
}

bool WiFiAPI::disconnect() {
    esp_wifi_disconnect();
    connected_ = false;
    return true;
}

bool WiFiAPI::isConnected() {
    return connected_;
}
