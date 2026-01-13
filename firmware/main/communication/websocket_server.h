#ifndef WEBSOCKET_SERVER_H
#define WEBSOCKET_SERVER_H

#include "esp_http_server.h"
#include <cstdint>

class WebSocketServer {
public:
    static WebSocketServer& getInstance() {
        static WebSocketServer instance;
        return instance;
    }
    
    bool initialize();
    bool start(int port);
    bool stop();
    bool sendMessage(int fd, const uint8_t* data, size_t length);
    
private:
    WebSocketServer() = default;
    ~WebSocketServer() = default;
    WebSocketServer(const WebSocketServer&) = delete;
    WebSocketServer& operator=(const WebSocketServer&) = delete;
    
    httpd_handle_t server_;
    bool running_;
};

#endif // WEBSOCKET_SERVER_H
