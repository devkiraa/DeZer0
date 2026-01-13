#include "display_api.h"
#include "esp_log.h"
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static const char* TAG = "DisplayAPI";

// SSD1306 commands
#define SSD1306_SETCONTRAST 0x81
#define SSD1306_DISPLAYALLON_RESUME 0xA4
#define SSD1306_DISPLAYALLON 0xA5
#define SSD1306_NORMALDISPLAY 0xA6
#define SSD1306_INVERTDISPLAY 0xA7
#define SSD1306_DISPLAYOFF 0xAE
#define SSD1306_DISPLAYON 0xAF
#define SSD1306_SETDISPLAYOFFSET 0xD3
#define SSD1306_SETCOMPINS 0xDA
#define SSD1306_SETVCOMDETECT 0xDB
#define SSD1306_SETDISPLAYCLOCKDIV 0xD5
#define SSD1306_SETPRECHARGE 0xD9
#define SSD1306_SETMULTIPLEX 0xA8
#define SSD1306_SETLOWCOLUMN 0x00
#define SSD1306_SETHIGHCOLUMN 0x10
#define SSD1306_SETSTARTLINE 0x40
#define SSD1306_MEMORYMODE 0x20
#define SSD1306_COLUMNADDR 0x21
#define SSD1306_PAGEADDR 0x22
#define SSD1306_COMSCANINC 0xC0
#define SSD1306_COMSCANDEC 0xC8
#define SSD1306_SEGREMAP 0xA0
#define SSD1306_CHARGEPUMP 0x8D

bool DisplayAPI::initialize() {
    ESP_LOGI(TAG, "Initializing SSD1306 display");
    
    width_ = 128;
    height_ = 64;
    
    // Allocate framebuffer
    size_t fb_size = (width_ * height_) / 8;
    framebuffer_ = (uint8_t*)malloc(fb_size);
    if (!framebuffer_) {
        ESP_LOGE(TAG, "Failed to allocate framebuffer");
        return false;
    }
    memset(framebuffer_, 0, fb_size);
    
    // Configure SPI bus
    spi_bus_config_t buscfg = {};
    buscfg.miso_io_num = -1;
    buscfg.mosi_io_num = PIN_MOSI;
    buscfg.sclk_io_num = PIN_SCK;
    buscfg.quadwp_io_num = -1;
    buscfg.quadhd_io_num = -1;
    buscfg.max_transfer_sz = 4096;
    
    esp_err_t ret = spi_bus_initialize(SPI2_HOST, &buscfg, SPI_DMA_CH_AUTO);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to initialize SPI bus: %s", esp_err_to_name(ret));
        free(framebuffer_);
        return false;
    }
    
    // Configure SPI device
    spi_device_interface_config_t devcfg = {};
    devcfg.clock_speed_hz = 10 * 1000 * 1000;  // 10 MHz
    devcfg.mode = 0;
    devcfg.spics_io_num = PIN_CS;
    devcfg.queue_size = 7;
    
    ret = spi_bus_add_device(SPI2_HOST, &devcfg, &spi_);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to add SPI device: %s", esp_err_to_name(ret));
        spi_bus_free(SPI2_HOST);
        free(framebuffer_);
        return false;
    }
    
    // Configure GPIO pins
    gpio_config_t io_conf = {};
    io_conf.intr_type = GPIO_INTR_DISABLE;
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pin_bit_mask = (1ULL << PIN_DC) | (1ULL << PIN_RST);
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;
    gpio_config(&io_conf);
    
    // Reset display
    gpio_set_level((gpio_num_t)PIN_RST, 0);
    vTaskDelay(pdMS_TO_TICKS(10));
    gpio_set_level((gpio_num_t)PIN_RST, 1);
    vTaskDelay(pdMS_TO_TICKS(10));
    
    // Initialize display
    sendCommand(SSD1306_DISPLAYOFF);
    sendCommand(SSD1306_SETDISPLAYCLOCKDIV);
    sendCommand(0x80);
    sendCommand(SSD1306_SETMULTIPLEX);
    sendCommand(height_ - 1);
    sendCommand(SSD1306_SETDISPLAYOFFSET);
    sendCommand(0x0);
    sendCommand(SSD1306_SETSTARTLINE | 0x0);
    sendCommand(SSD1306_CHARGEPUMP);
    sendCommand(0x14);
    sendCommand(SSD1306_MEMORYMODE);
    sendCommand(0x00);
    sendCommand(SSD1306_SEGREMAP | 0x1);
    sendCommand(SSD1306_COMSCANDEC);
    sendCommand(SSD1306_SETCOMPINS);
    sendCommand(0x12);
    sendCommand(SSD1306_SETCONTRAST);
    sendCommand(0xCF);
    sendCommand(SSD1306_SETPRECHARGE);
    sendCommand(0xF1);
    sendCommand(SSD1306_SETVCOMDETECT);
    sendCommand(0x40);
    sendCommand(SSD1306_DISPLAYALLON_RESUME);
    sendCommand(SSD1306_NORMALDISPLAY);
    sendCommand(SSD1306_DISPLAYON);
    
    initialized_ = true;
    ESP_LOGI(TAG, "Display initialized: %dx%d", width_, height_);
    
    return true;
}

void DisplayAPI::deinit() {
    if (initialized_) {
        spi_bus_remove_device(spi_);
        spi_bus_free(SPI2_HOST);
        free(framebuffer_);
        initialized_ = false;
    }
}

void DisplayAPI::clear() {
    if (framebuffer_) {
        memset(framebuffer_, 0, (width_ * height_) / 8);
    }
}

void DisplayAPI::update() {
    if (!initialized_ || !framebuffer_) {
        return;
    }
    
    sendCommand(SSD1306_COLUMNADDR);
    sendCommand(0);
    sendCommand(width_ - 1);
    sendCommand(SSD1306_PAGEADDR);
    sendCommand(0);
    sendCommand((height_ / 8) - 1);
    
    sendData(framebuffer_, (width_ * height_) / 8);
}

void DisplayAPI::drawPixel(int x, int y, bool color) {
    if (x < 0 || x >= width_ || y < 0 || y >= height_) {
        return;
    }
    
    int byte_index = x + (y / 8) * width_;
    int bit_index = y % 8;
    
    if (color) {
        framebuffer_[byte_index] |= (1 << bit_index);
    } else {
        framebuffer_[byte_index] &= ~(1 << bit_index);
    }
}

void DisplayAPI::drawLine(int x1, int y1, int x2, int y2, bool color) {
    int dx = abs(x2 - x1);
    int dy = abs(y2 - y1);
    int sx = x1 < x2 ? 1 : -1;
    int sy = y1 < y2 ? 1 : -1;
    int err = dx - dy;
    
    while (true) {
        drawPixel(x1, y1, color);
        
        if (x1 == x2 && y1 == y2) break;
        
        int e2 = 2 * err;
        if (e2 > -dy) {
            err -= dy;
            x1 += sx;
        }
        if (e2 < dx) {
            err += dx;
            y1 += sy;
        }
    }
}

void DisplayAPI::drawRect(int x, int y, int w, int h, bool fill, bool color) {
    if (fill) {
        for (int i = 0; i < h; i++) {
            for (int j = 0; j < w; j++) {
                drawPixel(x + j, y + i, color);
            }
        }
    } else {
        drawLine(x, y, x + w - 1, y, color);
        drawLine(x + w - 1, y, x + w - 1, y + h - 1, color);
        drawLine(x + w - 1, y + h - 1, x, y + h - 1, color);
        drawLine(x, y + h - 1, x, y, color);
    }
}

void DisplayAPI::drawCircle(int x, int y, int r, bool fill, bool color) {
    int f = 1 - r;
    int ddF_x = 1;
    int ddF_y = -2 * r;
    int px = 0;
    int py = r;
    
    drawPixel(x, y + r, color);
    drawPixel(x, y - r, color);
    drawPixel(x + r, y, color);
    drawPixel(x - r, y, color);
    
    while (px < py) {
        if (f >= 0) {
            py--;
            ddF_y += 2;
            f += ddF_y;
        }
        px++;
        ddF_x += 2;
        f += ddF_x;
        
        if (fill) {
            drawLine(x - px, y + py, x + px, y + py, color);
            drawLine(x - px, y - py, x + px, y - py, color);
            drawLine(x - py, y + px, x + py, y + px, color);
            drawLine(x - py, y - px, x + py, y - px, color);
        } else {
            drawPixel(x + px, y + py, color);
            drawPixel(x - px, y + py, color);
            drawPixel(x + px, y - py, color);
            drawPixel(x - px, y - py, color);
            drawPixel(x + py, y + px, color);
            drawPixel(x - py, y + px, color);
            drawPixel(x + py, y - px, color);
            drawPixel(x - py, y - px, color);
        }
    }
}

void DisplayAPI::drawText(int x, int y, const std::string& text, int size) {
    // Simple 8x8 font rendering - would need font data in production
    // For now, just placeholder
    drawRect(x, y, text.length() * 8 * size, 8 * size, false, true);
}

void DisplayAPI::setBrightness(uint8_t brightness) {
    sendCommand(SSD1306_SETCONTRAST);
    sendCommand(brightness);
}

void DisplayAPI::setContrast(uint8_t contrast) {
    setBrightness(contrast);
}

void DisplayAPI::sendCommand(uint8_t cmd) {
    gpio_set_level((gpio_num_t)PIN_DC, 0);  // Command mode
    
    spi_transaction_t trans = {};
    trans.length = 8;
    trans.tx_buffer = &cmd;
    
    spi_device_polling_transmit(spi_, &trans);
}

void DisplayAPI::sendData(uint8_t* data, size_t len) {
    gpio_set_level((gpio_num_t)PIN_DC, 1);  // Data mode
    
    spi_transaction_t trans = {};
    trans.length = len * 8;
    trans.tx_buffer = data;
    
    spi_device_polling_transmit(spi_, &trans);
}
