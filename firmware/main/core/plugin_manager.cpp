#include "plugin_manager.h"
#include "storage_manager.h"
#include "payload_loader.h"
#include "esp_log.h"
#include <string.h>
#include "esp_timer.h"
#include "cJSON.h"
#include "esp_system.h"

static const char* TAG = "PluginManager";

bool PluginManager::initialize() {
    ESP_LOGI(TAG, "Initializing Plugin Manager");
    manifests_.clear();
    contexts_.clear();
    return true;
}

int PluginManager::scanPayloads() {
    ESP_LOGI(TAG, "Scanning for payloads...");
    
    auto& storage = StorageManager::getInstance();
    auto payload_dirs = storage.listDirectory(PAYLOAD_BASE_PATH);
    
    int count = 0;
    for (const auto& dir : payload_dirs) {
        PayloadManifest manifest;
        if (loadManifest(dir.c_str(), manifest)) {
            if (validateManifest(manifest)) {
                manifests_[dir] = manifest;
                count++;
                ESP_LOGI(TAG, "Loaded payload: %s (%s)", manifest.name.c_str(), dir.c_str());
            } else {
                ESP_LOGW(TAG, "Invalid manifest for payload: %s", dir.c_str());
            }
        }
    }
    
    ESP_LOGI(TAG, "Found %d valid payloads", count);
    return count;
}

std::vector<PayloadManifest> PluginManager::getAvailablePayloads() {
    std::vector<PayloadManifest> payloads;
    for (const auto& pair : manifests_) {
        payloads.push_back(pair.second);
    }
    return payloads;
}

PayloadManifest* PluginManager::getPayloadManifest(const char* payload_id) {
    auto it = manifests_.find(payload_id);
    if (it != manifests_.end()) {
        return &it->second;
    }
    return nullptr;
}

bool PluginManager::installPayload(const char* payload_id, const uint8_t* data, size_t size) {
    ESP_LOGI(TAG, "Installing payload: %s (%d bytes)", payload_id, size);
    
    auto& storage = StorageManager::getInstance();
    
    // Create payload directory
    std::string payload_dir = storage.getPayloadPath(payload_id);
    if (!storage.createDirectory(payload_dir.c_str())) {
        ESP_LOGE(TAG, "Failed to create payload directory");
        return false;
    }
    
    // Write payload data
    std::string payload_path = storage.getPayloadDataPath(payload_id);
    if (!storage.writeFile(payload_path.c_str(), data, size)) {
        ESP_LOGE(TAG, "Failed to write payload data");
        storage.deleteDirectory(payload_dir.c_str());
        return false;
    }
    
    ESP_LOGI(TAG, "Payload installed successfully");
    
    // Rescan to load manifest
    scanPayloads();
    
    return true;
}

bool PluginManager::uninstallPayload(const char* payload_id) {
    ESP_LOGI(TAG, "Uninstalling payload: %s", payload_id);
    
    // Stop if running
    if (getPayloadStatus(payload_id) == PAYLOAD_STATUS_RUNNING) {
        stopPayload(payload_id);
    }
    
    // Delete from storage
    auto& storage = StorageManager::getInstance();
    std::string payload_dir = storage.getPayloadPath(payload_id);
    if (!storage.deleteDirectory(payload_dir.c_str())) {
        ESP_LOGE(TAG, "Failed to delete payload directory");
        return false;
    }
    
    // Remove from manifests
    manifests_.erase(payload_id);
    contexts_.erase(payload_id);
    
    ESP_LOGI(TAG, "Payload uninstalled successfully");
    return true;
}

bool PluginManager::executePayload(const char* payload_id, const std::map<std::string, std::string>& params) {
    ESP_LOGI(TAG, "Executing payload: %s", payload_id);
    
    // Get manifest
    PayloadManifest* manifest = getPayloadManifest(payload_id);
    if (!manifest) {
        ESP_LOGE(TAG, "Payload not found: %s", payload_id);
        return false;
    }
    
    // Check if already running
    if (getPayloadStatus(payload_id) == PAYLOAD_STATUS_RUNNING) {
        ESP_LOGW(TAG, "Payload already running: %s", payload_id);
        return false;
    }
    
    // Check requirements
    if (!checkRequirements(*manifest)) {
        ESP_LOGE(TAG, "Requirements check failed");
        return false;
    }
    
    // Check permissions
    if (!checkPermissions(*manifest)) {
        ESP_LOGE(TAG, "Permission check failed");
        return false;
    }
    
    // Create context
    PayloadContext context;
    context.manifest = *manifest;
    context.status = PAYLOAD_STATUS_LOADING;
    context.runtime_handle = nullptr;
    context.user_data = nullptr;
    context.memory_allocated = 0;
    context.memory_limit = manifest->requirements.memory_kb * 1024;
    context.start_time = esp_timer_get_time() / 1000;
    context.cpu_time_limit = MAX_EXECUTION_TIME_MS;
    
    contexts_[payload_id] = context;
    
    // Load and execute payload
    bool success = PayloadLoader::getInstance().loadAndExecute(payload_id, &contexts_[payload_id], params);
    
    if (!success) {
        ESP_LOGE(TAG, "Failed to execute payload");
        contexts_[payload_id].status = PAYLOAD_STATUS_ERROR;
        return false;
    }
    
    ESP_LOGI(TAG, "Payload execution started successfully");
    return true;
}

bool PluginManager::stopPayload(const char* payload_id) {
    ESP_LOGI(TAG, "Stopping payload: %s", payload_id);
    
    auto it = contexts_.find(payload_id);
    if (it == contexts_.end()) {
        ESP_LOGW(TAG, "Payload context not found: %s", payload_id);
        return false;
    }
    
    PayloadLoader::getInstance().stop(payload_id, &it->second);
    it->second.status = PAYLOAD_STATUS_COMPLETED;
    
    ESP_LOGI(TAG, "Payload stopped");
    return true;
}

PayloadContext* PluginManager::getPayloadContext(const char* payload_id) {
    auto it = contexts_.find(payload_id);
    if (it != contexts_.end()) {
        return &it->second;
    }
    return nullptr;
}

payload_status_t PluginManager::getPayloadStatus(const char* payload_id) {
    PayloadContext* ctx = getPayloadContext(payload_id);
    return ctx ? ctx->status : PAYLOAD_STATUS_IDLE;
}

void PluginManager::update() {
    // Check running payloads for timeouts and errors
    for (auto& pair : contexts_) {
        PayloadContext& ctx = pair.second;
        
        if (ctx.status == PAYLOAD_STATUS_RUNNING) {
            uint64_t elapsed = (esp_timer_get_time() / 1000) - ctx.start_time;
            
            // Check execution time limit
            if (elapsed > ctx.cpu_time_limit) {
                ESP_LOGW(TAG, "Payload timeout: %s", pair.first.c_str());
                stopPayload(pair.first.c_str());
            }
            
            // Check memory limit
            if (ctx.memory_allocated > ctx.memory_limit) {
                ESP_LOGW(TAG, "Payload memory exceeded: %s", pair.first.c_str());
                stopPayload(pair.first.c_str());
            }
        }
    }
}

bool PluginManager::loadManifest(const char* payload_id, PayloadManifest& manifest) {
    auto& storage = StorageManager::getInstance();
    std::string manifest_path = storage.getPayloadManifestPath(payload_id);
    
    // Check if manifest exists
    if (!storage.fileExists(manifest_path.c_str())) {
        ESP_LOGW(TAG, "Manifest not found: %s", manifest_path.c_str());
        return false;
    }
    
    // Read manifest file
    uint8_t buffer[4096];
    int size = storage.readFile(manifest_path.c_str(), buffer, sizeof(buffer));
    if (size <= 0) {
        ESP_LOGE(TAG, "Failed to read manifest: %s", manifest_path.c_str());
        return false;
    }
    
    buffer[size] = '\0';
    
    // Parse JSON
    cJSON* root = cJSON_Parse((const char*)buffer);
    if (!root) {
        ESP_LOGE(TAG, "Failed to parse manifest JSON");
        return false;
    }
    
    // Extract fields
    cJSON* id = cJSON_GetObjectItem(root, "id");
    cJSON* name = cJSON_GetObjectItem(root, "name");
    cJSON* version = cJSON_GetObjectItem(root, "version");
    
    if (!id || !name || !version) {
        ESP_LOGE(TAG, "Missing required fields in manifest");
        cJSON_Delete(root);
        return false;
    }
    
    manifest.id = id->valuestring;
    manifest.name = name->valuestring;
    manifest.version = version->valuestring;
    
    // Optional fields
    cJSON* author = cJSON_GetObjectItem(root, "author");
    if (author) manifest.author = author->valuestring;
    
    cJSON* description = cJSON_GetObjectItem(root, "description");
    if (description) manifest.description = description->valuestring;
    
    cJSON* category = cJSON_GetObjectItem(root, "category");
    if (category) manifest.category = category->valuestring;
    
    // Payload info
    cJSON* payload_obj = cJSON_GetObjectItem(root, "payload");
    if (payload_obj) {
        cJSON* type = cJSON_GetObjectItem(payload_obj, "type");
        if (type && strcmp(type->valuestring, "native") == 0) {
            manifest.payload.type = PAYLOAD_TYPE_NATIVE;
        } else if (type && strcmp(type->valuestring, "micropython") == 0) {
            manifest.payload.type = PAYLOAD_TYPE_MICROPYTHON;
        } else if (type && strcmp(type->valuestring, "lua") == 0) {
            manifest.payload.type = PAYLOAD_TYPE_LUA;
        }
        
        cJSON* entry = cJSON_GetObjectItem(payload_obj, "entry");
        if (entry) manifest.payload.entry = entry->valuestring;
    }
    
    // Requirements
    cJSON* requirements = cJSON_GetObjectItem(root, "requirements");
    if (requirements) {
        cJSON* memory = cJSON_GetObjectItem(requirements, "memory_kb");
        if (memory) manifest.requirements.memory_kb = memory->valueint;
        
        cJSON* storage = cJSON_GetObjectItem(requirements, "storage_kb");
        if (storage) manifest.requirements.storage_kb = storage->valueint;
    }
    
    // Permissions
    cJSON* permissions = cJSON_GetObjectItem(root, "permissions");
    if (permissions) {
        manifest.permissions = 0;
        cJSON* perm = permissions->child;
        while (perm) {
            if (strcmp(perm->valuestring, "wifi_scan") == 0) {
                manifest.permissions |= PERM_WIFI_SCAN;
            } else if (strcmp(perm->valuestring, "wifi_inject") == 0) {
                manifest.permissions |= PERM_WIFI_INJECT;
            } else if (strcmp(perm->valuestring, "ble_scan") == 0) {
                manifest.permissions |= PERM_BLE_SCAN;
            } else if (strcmp(perm->valuestring, "gpio_write") == 0) {
                manifest.permissions |= PERM_GPIO_WRITE;
            }
            perm = perm->next;
        }
    }
    
    cJSON_Delete(root);
    return true;
}

bool PluginManager::validateManifest(const PayloadManifest& manifest) {
    // Check required fields
    if (manifest.id.empty() || manifest.name.empty() || manifest.version.empty()) {
        ESP_LOGE(TAG, "Missing required manifest fields");
        return false;
    }
    
    // Validate payload type
    if (manifest.payload.type != PAYLOAD_TYPE_NATIVE &&
        manifest.payload.type != PAYLOAD_TYPE_MICROPYTHON &&
        manifest.payload.type != PAYLOAD_TYPE_LUA &&
        manifest.payload.type != PAYLOAD_TYPE_BUILTIN) {
        ESP_LOGE(TAG, "Invalid payload type");
        return false;
    }
    
    return true;
}

bool PluginManager::checkPermissions(const PayloadManifest& manifest) {
    // TODO: Implement permission checking logic
    // For now, allow all permissions
    return true;
}

bool PluginManager::checkRequirements(const PayloadManifest& manifest) {
    // Check memory requirement
    size_t free_heap = esp_get_free_heap_size();
    size_t required_memory = manifest.requirements.memory_kb * 1024;
    
    if (free_heap < required_memory) {
        ESP_LOGE(TAG, "Insufficient memory: need %lu KB, have %lu KB", 
                 (unsigned long)manifest.requirements.memory_kb, (unsigned long)(free_heap / 1024));
        return false;
    }
    
    // Check storage requirement
    auto& storage = StorageManager::getInstance();
    size_t free_storage = storage.getFreeSpace();
    size_t required_storage = manifest.requirements.storage_kb * 1024;
    
    if (free_storage < required_storage) {
        ESP_LOGE(TAG, "Insufficient storage: need %lu KB, have %lu KB",
                 (unsigned long)manifest.requirements.storage_kb, (unsigned long)(free_storage / 1024));
        return false;
    }
    
    return true;
}
