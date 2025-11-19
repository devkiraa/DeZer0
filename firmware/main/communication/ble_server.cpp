#include "ble_server.h"
#include "esp_log.h"
#include "esp_bt.h"
#include "esp_bt_main.h"

static const char* TAG = "BLEServer";

#define DEZERO_SERVICE_UUID 0x00FF
#define DEZERO_CHAR_UUID 0xFF01

bool BLEServer::initialize() {
    ESP_LOGI(TAG, "Initializing BLE Server");
    
    esp_bt_controller_config_t bt_cfg = BT_CONTROLLER_INIT_CONFIG_DEFAULT();
    esp_bt_controller_init(&bt_cfg);
    esp_bt_controller_enable(ESP_BT_MODE_BLE);
    
    esp_bluedroid_init();
    esp_bluedroid_enable();
    
    running_ = false;
    return true;
}

bool BLEServer::start() {
    ESP_LOGI(TAG, "Starting BLE Server");
    
    esp_ble_gap_set_device_name("DeZero");
    
    esp_ble_adv_data_t adv_data = {};
    adv_data.set_scan_rsp = false;
    adv_data.include_name = true;
    adv_data.include_txpower = true;
    adv_data.min_interval = 0x20;
    adv_data.max_interval = 0x40;
    adv_data.appearance = 0x00;
    adv_data.manufacturer_len = 0;
    adv_data.p_manufacturer_data = NULL;
    adv_data.service_data_len = 0;
    adv_data.p_service_data = NULL;
    adv_data.service_uuid_len = 0;
    adv_data.p_service_uuid = NULL;
    adv_data.flag = (ESP_BLE_ADV_FLAG_GEN_DISC | ESP_BLE_ADV_FLAG_BREDR_NOT_SPT);
    
    esp_ble_gap_config_adv_data(&adv_data);
    
    esp_ble_adv_params_t adv_params = {};
    adv_params.adv_int_min = 0x20;
    adv_params.adv_int_max = 0x40;
    adv_params.adv_type = ADV_TYPE_IND;
    adv_params.own_addr_type = BLE_ADDR_TYPE_PUBLIC;
    adv_params.channel_map = ADV_CHNL_ALL;
    adv_params.adv_filter_policy = ADV_FILTER_ALLOW_SCAN_ANY_CON_ANY;
    
    esp_ble_gap_start_advertising(&adv_params);
    
    running_ = true;
    ESP_LOGI(TAG, "BLE Server started");
    
    return true;
}

bool BLEServer::stop() {
    if (running_) {
        esp_ble_gap_stop_advertising();
        running_ = false;
    }
    return true;
}

bool BLEServer::sendNotification(const uint8_t* data, size_t length) {
    if (!running_) {
        return false;
    }
    
    // TODO: Implement notification sending
    ESP_LOGI(TAG, "Sending notification: %d bytes", length);
    return true;
}

void BLEServer::gapEventHandler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t* param) {
    // Handle GAP events
}

void BLEServer::gattsEventHandler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t* param) {
    // Handle GATT server events
}
