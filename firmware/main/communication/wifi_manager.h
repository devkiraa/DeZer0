#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include "esp_wifi.h"

class WiFiManager {
public:
    static WiFiManager& getInstance() {
        static WiFiManager instance;
        return instance;
    }
    
    bool initialize();
    bool startAP(const char* ssid, const char* password);
    bool stopAP();
    bool connectSTA(const char* ssid, const char* password);
    bool disconnect();
    
private:
    WiFiManager() = default;
    ~WiFiManager() = default;
    WiFiManager(const WiFiManager&) = delete;
    WiFiManager& operator=(const WiFiManager&) = delete;
    
    bool initialized_;
};

#endif // WIFI_MANAGER_H
