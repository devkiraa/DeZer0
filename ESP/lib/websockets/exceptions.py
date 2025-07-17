class WebsocketError(Exception):
    pass

class ConnectionClosed(WebsocketError):
    def __init__(self, reason=None):
        self.reason = reason
    def __str__(self):
        return 'Connection closed, reason: {}'.format(self.reason)