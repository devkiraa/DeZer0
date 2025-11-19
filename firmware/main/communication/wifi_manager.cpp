#include "wifi_manager.h"
#include "esp_log.h"
#include "esp_event.h"
#include "nvs_flash.h"
#include <cstring>

static const char* TAG = "WiFiManager";

bool WiFiManager::initialize() {
    ESP_LOGI(TAG, "Initializing WiFi Manager");
    
    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    
    esp_netif_create_default_wifi_ap();
    esp_netif_create_default_wifi_sta();
    
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));
    
    initialized_ = true;
    return true;
}

bool WiFiManager::startAP(const char* ssid, const char* password) {
    ESP_LOGI(TAG, "Starting AP: %s", ssid);
    
    wifi_config_t wifi_config = {};
    strcpy((char*)wifi_config.ap.ssid, ssid);
    strcpy((char*)wifi_config.ap.password, password);
    wifi_config.ap.ssid_len = strlen(ssid);
    wifi_config.ap.channel = 1;
    wifi_config.ap.max_connection = 4;
    wifi_config.ap.authmode = WIFI_AUTH_WPA_WPA2_PSK;
    
    if (strlen(password) == 0) {
        wifi_config.ap.authmode = WIFI_AUTH_OPEN;
    }
    
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_AP));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_AP, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());
    
    return true;
}

bool WiFiManager::stopAP() {
    esp_wifi_stop();
    return true;
}

bool WiFiManager::connectSTA(const char* ssid, const char* password) {
    ESP_LOGI(TAG, "Connecting to: %s", ssid);
    
    wifi_config_t wifi_config = {};
    strcpy((char*)wifi_config.sta.ssid, ssid);
    strcpy((char*)wifi_config.sta.password, password);
    
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());
    ESP_ERROR_CHECK(esp_wifi_connect());
    
    return true;
}

bool WiFiManager::disconnect() {
    esp_wifi_disconnect();
    return true;
}
