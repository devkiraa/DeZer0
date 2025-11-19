#ifndef DEZERO_PAYLOAD_API_H
#define DEZERO_PAYLOAD_API_H

#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

// ============================================================================
// WiFi API
// ============================================================================

typedef struct {
    char ssid[33];
    uint8_t bssid[6];
    int8_t rssi;
    uint8_t channel;
    uint8_t auth_mode;
} wifi_ap_record_t;

// Start WiFi scan
int dezero_wifi_scan_start();

// Get scan results
int dezero_wifi_scan_get_results(wifi_ap_record_t* results, int max_results);

// Set WiFi mode (STA/AP)
int dezero_wifi_set_mode(int mode);

// Connect to AP
int dezero_wifi_connect(const char* ssid, const char* password);

// Disconnect from AP
int dezero_wifi_disconnect();

// Get connection status
int dezero_wifi_get_status(char* ip_addr, int ip_len);

// Send deauth frame (requires PERM_WIFI_INJECT)
int dezero_wifi_send_deauth(const uint8_t* bssid, const uint8_t* sta_mac);

// ============================================================================
// BLE API
// ============================================================================

typedef struct {
    uint8_t addr[6];
    int8_t rssi;
    char name[32];
    uint8_t addr_type;
} ble_device_t;

// Start BLE scan
int dezero_ble_scan_start(int duration_ms);

// Get BLE scan results
int dezero_ble_scan_get_results(ble_device_t* results, int max_results);

// Stop BLE scan
int dezero_ble_scan_stop();

// Start BLE advertising (requires PERM_BLE_ADVERTISE)
int dezero_ble_advertise_start(const char* name, const uint8_t* adv_data, int adv_len);

// Stop BLE advertising
int dezero_ble_advertise_stop();

// ============================================================================
// GPIO API
// ============================================================================

// Configure GPIO pin
int dezero_gpio_config(int pin, int mode, int pull);

// Read GPIO pin
int dezero_gpio_read(int pin);

// Write GPIO pin (requires PERM_GPIO_WRITE)
int dezero_gpio_write(int pin, int value);

// Configure PWM
int dezero_gpio_pwm_config(int pin, int frequency, int duty_cycle);

// ============================================================================
// Display API
// ============================================================================

// Clear display
int dezero_display_clear();

// Draw text
int dezero_display_text(int x, int y, const char* text, int font_size);

// Draw rectangle
int dezero_display_rect(int x, int y, int width, int height, int fill);

// Draw line
int dezero_display_line(int x1, int y1, int x2, int y2);

// Draw pixel
int dezero_display_pixel(int x, int y, int color);

// Update display (flush buffer)
int dezero_display_update();

// ============================================================================
// Storage API
// ============================================================================

// Open file
int dezero_storage_open(const char* path, int flags);

// Close file
int dezero_storage_close(int fd);

// Read from file
int dezero_storage_read(int fd, uint8_t* buffer, int size);

// Write to file (requires PERM_STORAGE_WRITE)
int dezero_storage_write(int fd, const uint8_t* buffer, int size);

// Delete file (requires PERM_STORAGE_WRITE)
int dezero_storage_delete(const char* path);

// List directory
int dezero_storage_list(const char* path, char** entries, int max_entries);

// Get file info
int dezero_storage_stat(const char* path, size_t* size, uint64_t* mtime);

// ============================================================================
// Logging API
// ============================================================================

void dezero_log_info(const char* format, ...);
void dezero_log_warn(const char* format, ...);
void dezero_log_error(const char* format, ...);
void dezero_log_debug(const char* format, ...);

// ============================================================================
// System API
// ============================================================================

// Get system info
typedef struct {
    char version[32];
    uint32_t uptime_ms;
    uint32_t free_heap;
    uint32_t total_heap;
    uint8_t battery_percent;
    bool usb_connected;
} system_info_t;

int dezero_system_get_info(system_info_t* info);

// Delay (yields to other tasks)
void dezero_delay(int ms);

// Get milliseconds since boot
uint64_t dezero_millis();

// Get payload parameter value
const char* dezero_get_param(const char* name);

// Send output to mobile app
int dezero_send_output(const uint8_t* data, size_t length);

// Request user input (blocking)
int dezero_request_input(char* buffer, int max_length, int timeout_ms);

// ============================================================================
// Network API (requires PERM_NETWORK)
// ============================================================================

// HTTP GET request
int dezero_http_get(const char* url, char* response, int max_length);

// HTTP POST request
int dezero_http_post(const char* url, const char* data, char* response, int max_length);

#ifdef __cplusplus
}
#endif

#endif // DEZERO_PAYLOAD_API_H
