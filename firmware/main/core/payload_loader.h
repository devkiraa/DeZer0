#ifndef PAYLOAD_LOADER_H
#define PAYLOAD_LOADER_H

#include <map>
#include <string>
#include "../include/types.h"

class PayloadLoader {
public:
    static PayloadLoader& getInstance() {
        static PayloadLoader instance;
        return instance;
    }
    
    bool loadAndExecute(const char* payload_id, PayloadContext* context,
                       const std::map<std::string, std::string>& params);
    bool stop(const char* payload_id, PayloadContext* context);
    
private:
    PayloadLoader() = default;
    ~PayloadLoader() = default;
    PayloadLoader(const PayloadLoader&) = delete;
    PayloadLoader& operator=(const PayloadLoader&) = delete;
    
    bool loadNative(const char* payload_id, PayloadContext* context,
                   const std::map<std::string, std::string>& params);
    bool loadMicroPython(const char* payload_id, PayloadContext* context,
                        const std::map<std::string, std::string>& params);
    bool loadLua(const char* payload_id, PayloadContext* context,
                const std::map<std::string, std::string>& params);
};

#endif // PAYLOAD_LOADER_H
