import uasyncio as asyncio
import ubinascii
import uhashlib
from .protocol import Websocket

class WebsocketServer(Websocket):
    is_client = False

async def accept(reader, writer):
    websocket = WebsocketServer()
    websocket.reader = reader
    websocket.writer = writer
    try:
        await websocket.handshake()
    except Exception:
        websocket.writer.close()
        await websocket.writer.wait_closed()
        raise
    return websocket

async def serve(handler, host, port):
    async def _handler(reader, writer):
        try:
            websocket = await accept(reader, writer)
            await handler(websocket)
        # FIX: Changed ConnectionError to the more general Exception
        except Exception:
            # The handshake failed or the client disconnected improperly, so we do nothing.
            pass

    return await asyncio.start_server(_handler, host, port)

async def handshake(self):
    try:
        key = await self._read_request()
        if not key:
            raise Exception("Missing Sec-WebSocket-Key")
        
        resp_key = ubinascii.b2a_base64(uhashlib.sha1(key + b"258EAFA5-E914-47DA-95CA-C5AB0DC85B11").digest()).strip()
        
        self.writer.write(b"HTTP/1.1 101 Switching Protocols\r\n"
                        b"Upgrade: websocket\r\n"
                        b"Connection: Upgrade\r\n"
                        b"Sec-WebSocket-Accept: " + resp_key + b"\r\n\r\n")
        await self.writer.drain()
    except Exception as e:
        raise Exception(f"Handshake error: {e}")

async def _read_request(self):
    key = None
    line = await self.reader.readline()
    while line and line != b"\r\n":
        if line.startswith(b"Sec-WebSocket-Key:"):
            key = line.split(b":", 1)[1].strip()
        line = await self.reader.readline()
    return key

Websocket.handshake = handshake