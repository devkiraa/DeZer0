#ifndef DEZERO_TYPES_H
#define DEZERO_TYPES_H

#include <stdint.h>
#include <stdbool.h>
#include <string>
#include <vector>

// Payload types
typedef enum {
    PAYLOAD_TYPE_NATIVE,        // Compiled C/C++ .so
    PAYLOAD_TYPE_MICROPYTHON,   // MicroPython .mpy
    PAYLOAD_TYPE_LUA,           // Lua script .lua
    PAYLOAD_TYPE_BUILTIN        // Built-in module
} payload_type_t;

// Payload status
typedef enum {
    PAYLOAD_STATUS_IDLE,
    PAYLOAD_STATUS_LOADING,
    PAYLOAD_STATUS_RUNNING,
    PAYLOAD_STATUS_PAUSED,
    PAYLOAD_STATUS_COMPLETED,
    PAYLOAD_STATUS_ERROR
} payload_status_t;

// Runtime types
typedef enum {
    RUNTIME_NATIVE,
    RUNTIME_MICROPYTHON,
    RUNTIME_LUA,
    RUNTIME_BUILTIN
} runtime_type_t;

// BLE device structure
struct ble_device_t {
    uint8_t address[6];        // MAC address
    int8_t rssi;               // Signal strength
    std::string name;          // Device name
    uint8_t* adv_data;         // Advertisement data
    size_t adv_data_len;       // Advertisement data length
};

// API permissions
typedef enum {
    PERM_WIFI_SCAN      = (1 << 0),
    PERM_WIFI_INJECT    = (1 << 1),
    PERM_BLE_SCAN       = (1 << 2),
    PERM_BLE_ADVERTISE  = (1 << 3),
    PERM_GPIO_READ      = (1 << 4),
    PERM_GPIO_WRITE     = (1 << 5),
    PERM_DISPLAY_WRITE  = (1 << 6),
    PERM_STORAGE_READ   = (1 << 7),
    PERM_STORAGE_WRITE  = (1 << 8),
    PERM_NETWORK        = (1 << 9)
} permission_flags_t;

// Payload manifest structure
struct PayloadManifest {
    std::string id;
    std::string name;
    std::string version;
    std::string author;
    std::string description;
    std::string category;
    
    struct {
        payload_type_t type;
        runtime_type_t runtime;
        std::string entry;
        std::string checksum;
        size_t size;
    } payload;
    
    struct {
        std::string min_firmware_version;
        std::vector<std::string> apis;
        uint32_t memory_kb;
        uint32_t storage_kb;
    } requirements;
    
    uint32_t permissions;
    
    struct Parameter {
        std::string name;
        std::string type;
        std::string label;
        bool required;
        std::string default_value;
    };
    std::vector<Parameter> parameters;
};

// Payload execution context
struct PayloadContext {
    PayloadManifest manifest;
    payload_status_t status;
    void* runtime_handle;
    void* user_data;
    uint32_t task_handle;
    
    // Resource limits
    size_t memory_allocated;
    size_t memory_limit;
    uint64_t start_time;
    uint64_t cpu_time_limit;
    
    // Callbacks
    void (*log_callback)(const char* message);
    void (*status_callback)(payload_status_t status);
    void (*output_callback)(const uint8_t* data, size_t length);
};

// Communication protocol commands
typedef enum {
    CMD_PING                = 0x01,
    CMD_GET_INFO            = 0x02,
    CMD_LIST_PAYLOADS       = 0x03,
    CMD_UPLOAD_PAYLOAD      = 0x04,
    CMD_DELETE_PAYLOAD      = 0x05,
    CMD_EXECUTE_PAYLOAD     = 0x06,
    CMD_STOP_PAYLOAD        = 0x07,
    CMD_GET_PAYLOAD_STATUS  = 0x08,
    CMD_GET_LOGS            = 0x09,
    CMD_OTA_BEGIN           = 0x10,
    CMD_OTA_WRITE           = 0x11,
    CMD_OTA_END             = 0x12,
    CMD_REBOOT              = 0xFF
} command_type_t;

// Response codes
typedef enum {
    RESP_OK                 = 0x00,
    RESP_ERROR              = 0x01,
    RESP_INVALID_COMMAND    = 0x02,
    RESP_INVALID_PARAMS     = 0x03,
    RESP_PERMISSION_DENIED  = 0x04,
    RESP_NOT_FOUND          = 0x05,
    RESP_ALREADY_RUNNING    = 0x06,
    RESP_OUT_OF_MEMORY      = 0x07,
    RESP_STORAGE_FULL       = 0x08
} response_code_t;

// System configuration
#define DEZERO_VERSION "2.0.0"
#define MAX_PAYLOAD_SIZE (512 * 1024)  // 512KB max payload
#define MAX_PAYLOADS 32
#define PAYLOAD_BASE_PATH "/spiffs/payloads"
#define MAX_EXECUTION_TIME_MS (60 * 1000)  // 60 seconds
#define MAX_MEMORY_PER_PAYLOAD (128 * 1024)  // 128KB

#endif // DEZERO_TYPES_H
