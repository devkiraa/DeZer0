#ifndef NATIVE_LOADER_H
#define NATIVE_LOADER_H

#include "../include/types.h"
#include <map>
#include <string>

class NativeLoader {
public:
    static NativeLoader& getInstance() {
        static NativeLoader instance;
        return instance;
    }
    
    bool load(const char* payload_id, PayloadContext* context, 
              const std::map<std::string, std::string>& params);
    bool stop(PayloadContext* context);
    
private:
    NativeLoader() = default;
    ~NativeLoader() = default;
    NativeLoader(const NativeLoader&) = delete;
    NativeLoader& operator=(const NativeLoader&) = delete;
};

#endif // NATIVE_LOADER_H

