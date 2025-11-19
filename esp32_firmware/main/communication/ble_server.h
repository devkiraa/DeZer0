#ifndef BLE_SERVER_H
#define BLE_SERVER_H

#include "esp_gap_ble_api.h"
#include "esp_gatts_api.h"

class BLEServer {
public:
    static BLEServer& getInstance() {
        static BLEServer instance;
        return instance;
    }
    
    bool initialize();
    bool start();
    bool stop();
    bool sendNotification(const uint8_t* data, size_t length);
    
private:
    BLEServer() = default;
    ~BLEServer() = default;
    BLEServer(const BLEServer&) = delete;
    BLEServer& operator=(const BLEServer&) = delete;
    
    static void gapEventHandler(esp_gap_ble_cb_event_t event, esp_ble_gap_cb_param_t* param);
    static void gattsEventHandler(esp_gatts_cb_event_t event, esp_gatt_if_t gatts_if, esp_ble_gatts_cb_param_t* param);
    
    bool running_;
    uint16_t conn_id_;
    uint16_t service_handle_;
    uint16_t char_handle_;
};

#endif // BLE_SERVER_H
