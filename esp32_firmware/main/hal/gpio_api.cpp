#include "gpio_api.h"
#include "esp_log.h"

static const char* TAG = "GPIOAPI";

bool GPIOAPI::initialize() {
    ESP_LOGI(TAG, "Initializing GPIO API");
    return true;
}

bool GPIOAPI::configPin(int pin, int mode, int pull) {
    gpio_config_t io_conf = {};
    io_conf.pin_bit_mask = (1ULL << pin);
    io_conf.mode = (gpio_mode_t)mode;
    io_conf.pull_up_en = (gpio_pullup_t)(pull == 1);
    io_conf.pull_down_en = (gpio_pulldown_t)(pull == -1);
    return gpio_config(&io_conf) == ESP_OK;
}

int GPIOAPI::readPin(int pin) {
    return gpio_get_level((gpio_num_t)pin);
}

bool GPIOAPI::writePin(int pin, int value) {
    return gpio_set_level((gpio_num_t)pin, value) == ESP_OK;
}