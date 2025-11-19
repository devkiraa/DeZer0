#include "payload_loader.h"
#include "storage_manager.h"
#include "../runtimes/native_loader.h"
#include "../runtimes/micropython_vm.h"
#include "../runtimes/lua_vm.h"
#include "esp_log.h"

static const char* TAG = "PayloadLoader";

bool PayloadLoader::loadAndExecute(const char* payload_id, PayloadContext* context,
                                   const std::map<std::string, std::string>& params) {
    
    if (!context) {
        ESP_LOGE(TAG, "Invalid context");
        return false;
    }
    
    ESP_LOGI(TAG, "Loading payload: %s (type: %d)", payload_id, context->manifest.payload.type);
    
    context->status = PAYLOAD_STATUS_LOADING;
    
    bool success = false;
    
    switch (context->manifest.payload.type) {
        case PAYLOAD_TYPE_NATIVE:
            success = loadNative(payload_id, context, params);
            break;
            
        case PAYLOAD_TYPE_MICROPYTHON:
            success = loadMicroPython(payload_id, context, params);
            break;
            
        case PAYLOAD_TYPE_LUA:
            success = loadLua(payload_id, context, params);
            break;
            
        case PAYLOAD_TYPE_BUILTIN:
            ESP_LOGW(TAG, "Built-in payloads not yet implemented");
            success = false;
            break;
            
        default:
            ESP_LOGE(TAG, "Unknown payload type: %d", context->manifest.payload.type);
            success = false;
    }
    
    if (success) {
        context->status = PAYLOAD_STATUS_RUNNING;
        ESP_LOGI(TAG, "Payload loaded and executing");
    } else {
        context->status = PAYLOAD_STATUS_ERROR;
        ESP_LOGE(TAG, "Failed to load payload");
    }
    
    return success;
}

bool PayloadLoader::stop(const char* payload_id, PayloadContext* context) {
    if (!context) {
        return false;
    }
    
    ESP_LOGI(TAG, "Stopping payload: %s", payload_id);
    
    switch (context->manifest.payload.type) {
        case PAYLOAD_TYPE_NATIVE:
            NativeLoader::getInstance().stop(context);
            break;
            
        case PAYLOAD_TYPE_MICROPYTHON:
            MicroPythonVM::getInstance().stop(context);
            break;
            
        case PAYLOAD_TYPE_LUA:
            LuaVM::getInstance().stop(context);
            break;
            
        default:
            break;
    }
    
    context->status = PAYLOAD_STATUS_COMPLETED;
    return true;
}

bool PayloadLoader::loadNative(const char* payload_id, PayloadContext* context,
                               const std::map<std::string, std::string>& params) {
    return NativeLoader::getInstance().load(payload_id, context, params);
}

bool PayloadLoader::loadMicroPython(const char* payload_id, PayloadContext* context,
                                    const std::map<std::string, std::string>& params) {
    return MicroPythonVM::getInstance().load(payload_id, context, params);
}

bool PayloadLoader::loadLua(const char* payload_id, PayloadContext* context,
                            const std::map<std::string, std::string>& params) {
    return LuaVM::getInstance().load(payload_id, context, params);
}
