import uasyncio as asyncio
import random
import struct
import ubinascii
from .constants import *
from .exceptions import ConnectionClosed

class Websocket:
    is_client = False
    def __init__(self):
        self.reader = None
        self.writer = None
        self.open = True

    async def close(self, code=1000, reason=''):
        if self.open:
            await self.write_frame(OP_CLOSE, struct.pack('!H', code) + reason.encode())
            self.open = False

    async def read_frame(self, max_size=None):
        two_bytes = await self.reader.readexactly(2)
        fin, opcode, has_mask, length = struct.unpack('!BB', two_bytes)
        fin = fin & 0x80
        opcode = opcode & 0x0f
        if has_mask:
            mask = await self.reader.readexactly(4)
        if length == 126:
            length, = struct.unpack('!H', await self.reader.readexactly(2))
        elif length == 127:
            length, = struct.unpack('!Q', await self.reader.readexactly(8))
        if max_size and length > max_size:
            raise ValueError("Frame too large")
        data = await self.reader.readexactly(length)
        if has_mask:
            data = bytes(b ^ mask[i % 4] for i, b in enumerate(data))
        return fin, opcode, data

    async def write_frame(self, opcode, data=b''):
        fin = 0x80
        opcode = fin | opcode
        length = len(data)
        mask_bit = 0x80 if self.is_client else 0
        if length < 126:
            length_data = struct.pack('!B', mask_bit | length)
        elif length < 65536:
            length_data = struct.pack('!BH', mask_bit | 126, length)
        else:
            length_data = struct.pack('!BQ', mask_bit | 127, length)
        self.writer.write(struct.pack('!B', opcode))
        self.writer.write(length_data)
        if self.is_client:
            mask = bytes(random.getrandbits(8) for _ in range(4))
            self.writer.write(mask)
            data = bytes(b ^ mask[i % 4] for i, b in enumerate(data))
        self.writer.write(data)
        await self.writer.drain()

    async def recv(self):
        if not self.open: raise ConnectionClosed
        while True:
            fin, opcode, recv_data = await self.read_frame()
            if opcode == OP_TEXT:
                return recv_data.decode() if fin else await self._recv_cont(recv_data)
            elif opcode == OP_BINARY:
                return recv_data if fin else await self._recv_cont(recv_data)
            elif opcode == OP_CLOSE:
                await self.close()
                return None
            elif opcode == OP_PING:
                await self.write_frame(OP_PONG, recv_data)
            elif opcode == OP_PONG:
                pass
            
    async def _recv_cont(self, data):
         while True:
            fin, opcode, recv_data = await self.read_frame()
            if opcode == OP_CONT:
                data += recv_data
                if fin: return data
            # Other opcodes are not allowed in the middle of a fragmented message
            
    async def send(self, data):
        if not self.open: raise ConnectionClosed
        if isinstance(data, str):
            await self.write_frame(OP_TEXT, data.encode())
        elif isinstance(data, bytes):
            await self.write_frame(OP_BINARY, data)
        else:
            raise TypeError("Data must be str or bytes")