#ifndef BLE_SCANNER_H
#define BLE_SCANNER_H

#include "../include/types.h"
#include <map>
#include <string>

class BLEScanner {
public:
    static BLEScanner& getInstance() {
        static BLEScanner instance;
        return instance;
    }
    
    bool execute(const std::map<std::string, std::string>& params);
    
private:
    BLEScanner() = default;
    ~BLEScanner() = default;
    BLEScanner(const BLEScanner&) = delete;
    BLEScanner& operator=(const BLEScanner&) = delete;
};

#endif // BLE_SCANNER_H
