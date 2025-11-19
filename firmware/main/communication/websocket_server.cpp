#include "websocket_server.h"
#include "esp_log.h"
#include <cstring>
#include "esp_http_server.h"

static const char* TAG = "WebSocketServer";

bool WebSocketServer::initialize() {
    ESP_LOGI(TAG, "Initializing WebSocket Server");
    running_ = false;
    server_ = NULL;
    return true;
}

bool WebSocketServer::start(int port) {
    ESP_LOGI(TAG, "Starting WebSocket Server on port %d", port);
    
    httpd_config_t config = HTTPD_DEFAULT_CONFIG();
    config.server_port = port;
    
    if (httpd_start(&server_, &config) == ESP_OK) {
        running_ = true;
        return true;
    }
    
    return false;
}

bool WebSocketServer::stop() {
    if (server_) {
        httpd_stop(server_);
        server_ = NULL;
        running_ = false;
    }
    return true;
}

bool WebSocketServer::sendMessage(int fd, const uint8_t* data, size_t length) {
    if (!running_ || !server_) {
        return false;
    }
    
    httpd_ws_frame_t ws_pkt;
    memset(&ws_pkt, 0, sizeof(httpd_ws_frame_t));
    ws_pkt.type = HTTPD_WS_TYPE_BINARY;
    ws_pkt.payload = (uint8_t*)data;
    ws_pkt.len = length;
    
    return httpd_ws_send_frame_async(server_, fd, &ws_pkt) == ESP_OK;
}
