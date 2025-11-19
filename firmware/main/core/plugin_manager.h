#ifndef PLUGIN_MANAGER_H
#define PLUGIN_MANAGER_H

#include <string>
#include <vector>
#include <map>
#include "../include/types.h"

class PluginManager {
public:
    static PluginManager& getInstance() {
        static PluginManager instance;
        return instance;
    }
    
    bool initialize();
    
    // Payload discovery
    int scanPayloads();
    std::vector<PayloadManifest> getAvailablePayloads();
    PayloadManifest* getPayloadManifest(const char* payload_id);
    
    // Payload installation
    bool installPayload(const char* payload_id, const uint8_t* data, size_t size);
    bool uninstallPayload(const char* payload_id);
    
    // Payload execution
    bool executePayload(const char* payload_id, const std::map<std::string, std::string>& params);
    bool stopPayload(const char* payload_id);
    PayloadContext* getPayloadContext(const char* payload_id);
    payload_status_t getPayloadStatus(const char* payload_id);
    
    // Update loop
    void update();
    
private:
    PluginManager() = default;
    ~PluginManager() = default;
    PluginManager(const PluginManager&) = delete;
    PluginManager& operator=(const PluginManager&) = delete;
    
    bool loadManifest(const char* payload_id, PayloadManifest& manifest);
    bool validateManifest(const PayloadManifest& manifest);
    bool checkPermissions(const PayloadManifest& manifest);
    bool checkRequirements(const PayloadManifest& manifest);
    
    std::map<std::string, PayloadManifest> manifests_;
    std::map<std::string, PayloadContext> contexts_;
};

#endif // PLUGIN_MANAGER_H
