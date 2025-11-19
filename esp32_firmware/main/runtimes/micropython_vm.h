#ifndef MICROPYTHON_VM_H
#define MICROPYTHON_VM_H

#include "../include/types.h"
#include <map>
#include <string>

class MicroPythonVM {
public:
    static MicroPythonVM& getInstance() {
        static MicroPythonVM instance;
        return instance;
    }
    
    bool load(const char* payload_id, PayloadContext* context,
              const std::map<std::string, std::string>& params);
    bool stop(PayloadContext* context);
    
private:
    MicroPythonVM() = default;
    ~MicroPythonVM() = default;
    MicroPythonVM(const MicroPythonVM&) = delete;
    MicroPythonVM& operator=(const MicroPythonVM&) = delete;
};

#endif // MICROPYTHON_VM_H

