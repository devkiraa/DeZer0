"use client";

import { useState, useRef, useEffect } from "react";
import { ESPLoader, FlashOptions } from "esp-web-tools";

export default function Flasher() {
  const [logs, setLogs] = useState<string[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const [firmware, setFirmware] = useState<ArrayBuffer | null>(null);
  const [filesystem, setFilesystem] = useState<ArrayBuffer | null>(null);
  const esploader = useRef<ESPLoader | null>(null);

  useEffect(() => {
    const fetchFiles = async () => {
      try {
        const firmwareRes = await fetch("/firmware.bin");
        const firmwareData = await firmwareRes.arrayBuffer();
        setFirmware(firmwareData);
        addLog("Firmware loaded.");

        const filesystemRes = await fetch("/filesystem.bin");
        const filesystemData = await filesystemRes.arrayBuffer();
        setFilesystem(filesystemData);
        addLog("Filesystem loaded.");
      } catch (error) {
        console.error(error);
        addLog(`Error loading files: ${error}`);
      }
    };
    fetchFiles();
  }, []);

  const addLog = (log: string) => {
    setLogs((prevLogs) => [...prevLogs, log]);
  };

  const handleConnect = async () => {
    if (esploader.current && esploader.current.connected) {
        await esploader.current.disconnect();
        esploader.current = null;
        setIsConnected(false);
        addLog("Disconnected.");
        return;
    }
    try {
        const loader = new ESPLoader({
            transport: "web-serial",
            baudrate: 115200,
            log: (...args) => addLog(args.join(" ")),
        });
        esploader.current = loader;

        await loader.connect();
        setIsConnected(true);
        addLog("Connected!");
        const chip = await loader.chipName();
        addLog(`Chip: ${chip}`);
    } catch (error) {
        console.error(error);
        addLog(`Error: ${error}`);
    }
  };

  const handleFlash = async () => {
    if (!esploader.current || !firmware || !filesystem) {
      addLog("Not connected or files not loaded.");
      return;
    }

    addLog("Flashing...");

    try {
      const flashOptions: FlashOptions = {
        fileArray: [
          { data: firmware, address: 0x10000 },
          { data: filesystem, address: 0x110000 },
        ],
        flashSize: "4MB",
        flashFreq: "40m",
        flashMode: "dio",
        eraseAll: true,
      };
      await esploader.current.writeFlash(flashOptions);
      addLog("Flashed successfully!");
    } catch (error) {
      console.error(error);
      addLog(`Error flashing: ${error}`);
    }
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gray-100">
      <div className="w-full max-w-lg p-6 bg-white rounded-lg shadow-md">
        <h1 className="text-2xl font-bold text-center mb-4">DeZer0 Web Flasher</h1>
        <div className="flex justify-around mb-4">
          <button
            onClick={handleConnect}
            className={`px-4 py-2 font-bold text-white rounded ${isConnected ? 'bg-red-500 hover:bg-red-700' : 'bg-blue-500 hover:bg-blue-700'}`}
          >
            {isConnected ? 'Disconnect' : 'Connect'}
          </button>
          <button
            onClick={handleFlash}
            disabled={!isConnected || !firmware || !filesystem}
            className="px-4 py-2 font-bold text-white bg-green-500 rounded hover:bg-green-700 disabled:bg-gray-400"
          >
            Flash
          </button>
        </div>
        <div className="w-full h-64 p-2 overflow-y-auto bg-gray-200 rounded">
          {logs.map((log, index) => (
            <p key={index} className="font-mono text-sm">
              {log}
            </p>
          ))}
        </div>
      </div>
    </div>
  );
}
