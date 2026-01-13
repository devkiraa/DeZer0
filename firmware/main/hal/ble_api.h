#ifndef BLE_API_H
#define BLE_API_H

#include "../include/types.h"
#include <vector>

class BLEAPI {
public:
    static BLEAPI& getInstance() {
        static BLEAPI instance;
        return instance;
    }
    
    bool initialize();
    bool startScan(int duration_ms);
    bool stopScan();
    std::vector<ble_device_t> getScanResults();
    
private:
    BLEAPI() = default;
    ~BLEAPI() = default;
    BLEAPI(const BLEAPI&) = delete;
    BLEAPI& operator=(const BLEAPI&) = delete;
    
    bool initialized_;
};

#endif // BLE_API_H