#include "ble_api.h"
#include "esp_log.h"

static const char* TAG = "BLEAPI";

bool BLEAPI::initialize() {
    ESP_LOGI(TAG, "Initializing BLE API");
    initialized_ = true;
    return true;
}

bool BLEAPI::startScan(int duration_ms) {
    ESP_LOGI(TAG, "Starting BLE scan for %d ms", duration_ms);
    return true;
}

bool BLEAPI::stopScan() {
    ESP_LOGI(TAG, "Stopping BLE scan");
    return true;
}

std::vector<ble_device_t> BLEAPI::getScanResults() {
    return std::vector<ble_device_t>();
}