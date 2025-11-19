#ifndef WIFI_SCANNER_H
#define WIFI_SCANNER_H

#include "../include/types.h"
#include <map>
#include <string>

class WiFiScanner {
public:
    static WiFiScanner& getInstance() {
        static WiFiScanner instance;
        return instance;
    }
    
    bool execute(const std::map<std::string, std::string>& params);
    
private:
    WiFiScanner() = default;
    ~WiFiScanner() = default;
    WiFiScanner(const WiFiScanner&) = delete;
    WiFiScanner& operator=(const WiFiScanner&) = delete;
};

#endif // WIFI_SCANNER_H
