#include "lua_vm.h"
#include "esp_log.h"

static const char* TAG = "LuaVM";

bool LuaVM::load(const char* payload_id, PayloadContext* context,
                 const std::map<std::string, std::string>& params) {
    ESP_LOGI(TAG, "Loading Lua payload: %s", payload_id);
    
    // TODO: Initialize Lua VM and load .lua file
    ESP_LOGW(TAG, "Lua VM not yet implemented");
    
    context->status = PAYLOAD_STATUS_RUNNING;
    return true;
}

bool LuaVM::stop(PayloadContext* context) {
    ESP_LOGI(TAG, "Stopping Lua VM");
    
    // TODO: Cleanup Lua VM
    
    context->status = PAYLOAD_STATUS_COMPLETED;
    return true;
}
