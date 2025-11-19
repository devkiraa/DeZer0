#ifndef LUA_VM_H
#define LUA_VM_H

#include "../include/types.h"
#include <map>
#include <string>

class LuaVM {
public:
    static LuaVM& getInstance() {
        static LuaVM instance;
        return instance;
    }
    
    bool load(const char* payload_id, PayloadContext* context,
              const std::map<std::string, std::string>& params);
    bool stop(PayloadContext* context);
    
private:
    LuaVM() = default;
    ~LuaVM() = default;
    LuaVM(const LuaVM&) = delete;
    LuaVM& operator=(const LuaVM&) = delete;
};

#endif // LUA_VM_H

