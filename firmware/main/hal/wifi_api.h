#ifndef WIFI_API_H
#define WIFI_API_H

#include "esp_wifi.h"
#include "../include/types.h"
#include <vector>

class WiFiAPI {
public:
    static WiFiAPI& getInstance() {
        static WiFiAPI instance;
        return instance;
    }
    
    bool initialize();
    bool startScan();
    std::vector<wifi_ap_record_t> getScanResults();
    bool connect(const char* ssid, const char* password);
    bool disconnect();
    bool isConnected();
    
private:
    WiFiAPI() = default;
    ~WiFiAPI() = default;
    WiFiAPI(const WiFiAPI&) = delete;
    WiFiAPI& operator=(const WiFiAPI&) = delete;
    
    bool initialized_;
    bool connected_;
};

#endif // WIFI_API_H
