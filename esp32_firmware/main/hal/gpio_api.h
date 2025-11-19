#ifndef GPIO_API_H
#define GPIO_API_H

#include "driver/gpio.h"

class GPIOAPI {
public:
    static GPIOAPI& getInstance() {
        static GPIOAPI instance;
        return instance;
    }
    
    bool initialize();
    bool configPin(int pin, int mode, int pull);
    int readPin(int pin);
    bool writePin(int pin, int value);
    
private:
    GPIOAPI() = default;
    ~GPIOAPI() = default;
    GPIOAPI(const GPIOAPI&) = delete;
    GPIOAPI& operator=(const GPIOAPI&) = delete;
};

#endif // GPIO_API_H