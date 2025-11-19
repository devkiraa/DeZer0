#include "native_loader.h"
#include "../core/storage_manager.h"
#include "esp_log.h"

static const char* TAG = "NativeLoader";

bool NativeLoader::load(const char* payload_id, PayloadContext* context,
                        const std::map<std::string, std::string>& params) {
    ESP_LOGI(TAG, "Loading native payload: %s", payload_id);
    
    // TODO: Implement dynamic library loading
    // For now, return stub implementation
    ESP_LOGW(TAG, "Native payload loading not yet implemented");
    
    context->status = PAYLOAD_STATUS_RUNNING;
    return true;
}

bool NativeLoader::stop(PayloadContext* context) {
    ESP_LOGI(TAG, "Stopping native payload");
    
    // TODO: Unload dynamic library and cleanup
    
    context->status = PAYLOAD_STATUS_COMPLETED;
    return true;
}
