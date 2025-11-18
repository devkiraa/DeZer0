"use client";

import { useState, useRef, useEffect } from "react";
import { GitHubRelease, FirmwareFiles } from "@/types";
import { githubService } from "@/services/githubService";
import ReleaseSelect from "./ReleaseSelect";
import ProgressBar from "./ProgressBar";
import LogViewer from "./LogViewer";

// ESP Web Tools types
interface Transport {
  connect(): Promise<void>;
  disconnect(): Promise<void>;
  write(data: Uint8Array): Promise<void>;
  read(timeout?: number): Promise<Uint8Array>;
}

interface ESPLoaderOptions {
  transport: Transport;
  baudrate?: number;
  terminal?: {
    write: (data: string) => void;
    writeLine: (data: string) => void;
  };
  enableTracing?: boolean;
}

interface FlashOptions {
  fileArray: Array<{ data: string | ArrayBuffer; address: number }>;
  flashSize: string;
  flashMode: string;
  flashFreq: string;
  eraseAll: boolean;
  compress?: boolean;
  reportProgress?: (fileIndex: number, written: number, total: number) => void;
}

declare class ESPLoader {
  constructor(options: ESPLoaderOptions);
  main(): Promise<string>;
  flashId(): Promise<number>;
  hardReset(): Promise<void>;
  disconnect(): Promise<void>;
  writeFlash(options: FlashOptions): Promise<void>;
}

interface SerialPort {
  open(options: { baudRate: number }): Promise<void>;
  close(): Promise<void>;
  readable: ReadableStream<Uint8Array> | null;
  writable: WritableStream<Uint8Array> | null;
}

interface Navigator {
  serial: {
    requestPort(): Promise<SerialPort>;
  };
}

class Transport {
  private port: SerialPort;
  private reader: ReadableStreamDefaultReader<Uint8Array> | null = null;
  private writer: WritableStreamDefaultWriter<Uint8Array> | null = null;
  private leftOver: Uint8Array = new Uint8Array(0);

  constructor(port: SerialPort) {
    this.port = port;
  }

  async connect(): Promise<void> {
    if (!this.port.readable || !this.port.writable) {
      await this.port.open({ baudRate: 115200 });
    }
    this.reader = this.port.readable!.getReader();
    this.writer = this.port.writable!.getWriter();
  }

  async disconnect(): Promise<void> {
    if (this.reader) {
      await this.reader.cancel();
      this.reader.releaseLock();
      this.reader = null;
    }
    if (this.writer) {
      await this.writer.close();
      this.writer = null;
    }
    await this.port.close();
  }

  async write(data: Uint8Array): Promise<void> {
    if (!this.writer) throw new Error("Not connected");
    await this.writer.write(data);
  }

  async read(timeout = 0): Promise<Uint8Array> {
    if (!this.reader) throw new Error("Not connected");

    if (this.leftOver.length > 0) {
      const result = this.leftOver;
      this.leftOver = new Uint8Array(0);
      return result;
    }

    const readPromise = this.reader.read();
    
    if (timeout > 0) {
      const timeoutPromise = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error("Timeout")), timeout)
      );
      const result = await Promise.race([readPromise, timeoutPromise]);
      if (result.done) throw new Error("Stream closed");
      return result.value;
    } else {
      const result = await readPromise;
      if (result.done) throw new Error("Stream closed");
      return result.value;
    }
  }
}

export default function Flasher() {
  const [logs, setLogs] = useState<string[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const [isFlashing, setIsFlashing] = useState(false);
  const [selectedRelease, setSelectedRelease] = useState<GitHubRelease | null>(null);
  const [firmwareFiles, setFirmwareFiles] = useState<FirmwareFiles | null>(null);
  const [downloadProgress, setDownloadProgress] = useState(0);
  const [flashProgress, setFlashProgress] = useState(0);
  const [chipInfo, setChipInfo] = useState<string>("");
  
  const esploader = useRef<ESPLoader | null>(null);
  const portRef = useRef<SerialPort | null>(null);

  const addLog = (log: string) => {
    setLogs((prevLogs) => [...prevLogs, log]);
  };

  useEffect(() => {
    addLog("Welcome to DeZer0 Web Flasher!");
    addLog("Please select a firmware version and connect your ESP32 device.");
  }, []);

  const handleReleaseSelect = async (release: GitHubRelease) => {
    setSelectedRelease(release);
    addLog(`Selected release: ${release.name} (${release.tag_name})`);
    
    try {
      const files = await githubService.getFirmwareFiles(release);
      setFirmwareFiles(files);
      
      if (files.firmware) {
        addLog(`✓ Firmware found: ${files.firmware.name} (${githubService.formatFileSize(files.firmware.size)})`);
      } else {
        addLog("⚠ Warning: Firmware file not found in this release");
      }
      
      if (files.filesystem) {
        addLog(`✓ Filesystem found: ${files.filesystem.name} (${githubService.formatFileSize(files.filesystem.size)})`);
      } else {
        addLog("⚠ Warning: Filesystem file not found in this release");
      }
    } catch (error) {
      addLog(`Error loading firmware files: ${error}`);
    }
  };

  const handleConnect = async () => {
    if (isConnected && esploader.current) {
      try {
        await esploader.current.disconnect();
        esploader.current = null;
        portRef.current = null;
        setIsConnected(false);
        setChipInfo("");
        addLog("✓ Disconnected from device");
      } catch (error) {
        addLog(`Error disconnecting: ${error}`);
      }
      return;
    }

    try {
      addLog("Requesting serial port access...");
      const port = await (navigator as Navigator).serial.requestPort();
      portRef.current = port;
      
      const transport = new Transport(port);
      await transport.connect();
      
      addLog("Connecting to ESP32...");
      const loader = new ESPLoader({
        transport: transport,
        baudrate: 115200,
        terminal: {
          write: (data: string) => addLog(data),
          writeLine: (data: string) => addLog(data),
        },
        enableTracing: false,
      });
      
      esploader.current = loader;
      
      const chipName = await loader.main();
      setChipInfo(chipName);
      setIsConnected(true);
      addLog(`✓ Connected to ${chipName}`);
      
      const flashId = await loader.flashId();
      addLog(`Flash ID: 0x${flashId.toString(16)}`);
    } catch (error) {
      addLog(`Error connecting: ${error}`);
      if (esploader.current) {
        try {
          await esploader.current.disconnect();
        } catch (e) {
          // Ignore disconnect errors
        }
        esploader.current = null;
        portRef.current = null;
      }
    }
  };

  const handleFlash = async () => {
    if (!esploader.current || !isConnected) {
      addLog("⚠ Error: Device not connected");
      return;
    }

    if (!firmwareFiles?.firmware || !firmwareFiles?.filesystem) {
      addLog("⚠ Error: Firmware files not loaded. Please select a release.");
      return;
    }

    setIsFlashing(true);
    setFlashProgress(0);
    addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    addLog("Starting flash process...");

    try {
      // Download firmware
      addLog(`Downloading firmware: ${firmwareFiles.firmware.name}...`);
      setDownloadProgress(0);
      const firmwareData = await githubService.downloadFirmwareFile(
        firmwareFiles.firmware.url,
        (progress) => setDownloadProgress(progress)
      );
      addLog(`✓ Firmware downloaded (${githubService.formatFileSize(firmwareData.byteLength)})`);

      // Download filesystem
      addLog(`Downloading filesystem: ${firmwareFiles.filesystem.name}...`);
      setDownloadProgress(0);
      const filesystemData = await githubService.downloadFirmwareFile(
        firmwareFiles.filesystem.url,
        (progress) => setDownloadProgress(progress)
      );
      addLog(`✓ Filesystem downloaded (${githubService.formatFileSize(filesystemData.byteLength)})`);

      // Prepare flash options
      const config = await githubService.loadConfig();
      const flashConfig = config.flash.flashOptions;
      
      addLog("Erasing flash memory...");
      const flashOptions: FlashOptions = {
        fileArray: [
          { 
            data: firmwareData, 
            address: parseInt(flashConfig.firmware.address, 16) 
          },
          { 
            data: filesystemData, 
            address: parseInt(flashConfig.filesystem.address, 16) 
          },
        ],
        flashSize: flashConfig.flashSize,
        flashFreq: flashConfig.flashFreq,
        flashMode: flashConfig.flashMode,
        eraseAll: flashConfig.eraseAll,
        compress: true,
        reportProgress: (fileIndex: number, written: number, total: number) => {
          const progress = Math.round((written / total) * 100);
          setFlashProgress(progress);
          if (written === total) {
            addLog(`✓ File ${fileIndex + 1} written successfully`);
          }
        },
      };

      addLog("Writing firmware to flash...");
      await esploader.current.writeFlash(flashOptions);
      
      addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      addLog("✓ ✓ ✓ Flash completed successfully! ✓ ✓ ✓");
      addLog("You can now disconnect and restart your device.");
      setFlashProgress(100);
    } catch (error) {
      addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      addLog(`✗ Flash failed: ${error}`);
    } finally {
      setIsFlashing(false);
      setDownloadProgress(0);
    }
  };

  const canFlash = isConnected && !isFlashing && firmwareFiles?.firmware && firmwareFiles?.filesystem;

  return (
    <div className="min-h-screen bg-black py-8 px-4">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-8">
          <h1 className="text-3xl md:text-4xl font-bold text-white mb-3" style={{ fontFamily: 'Courier New, monospace' }}>
            ⚡ ESP32 FIRMWARE FLASHER
          </h1>
          <p className="text-[#B0B0B0] text-lg" style={{ fontFamily: 'Courier New, monospace' }}>
            FLASH YOUR ESP32 WITH THE LATEST DEZERO FIRMWARE
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Flash Panel */}
          <div className="lg:col-span-2">
            <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6 mb-6">
              {/* Device Info Bar */}
              {isConnected && chipInfo && (
                <div className="mb-6 p-4 bg-[#0d0d0d] border border-[#FF8C00]">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      <div className="w-3 h-3 bg-[#FF8C00] rounded-full animate-pulse"></div>
                      <span className="text-[#FF8C00] font-semibold" style={{ fontFamily: 'Courier New, monospace' }}>
                        CONNECTED TO {chipInfo.toUpperCase()}
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {/* Release Selection */}
              <div className="mb-6">
                <ReleaseSelect
                  onReleaseSelect={handleReleaseSelect}
                  selectedRelease={selectedRelease}
                />
              </div>

              {/* Action Buttons */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
                <button
                  onClick={handleConnect}
                  disabled={isFlashing}
                  className={`px-6 py-3 font-semibold transition-all disabled:opacity-50 disabled:cursor-not-allowed border ${
                    isConnected
                      ? "bg-black hover:bg-[#FF8C00] text-[#FF8C00] hover:text-black border-[#FF8C00]"
                      : "bg-[#FF8C00] hover:bg-black text-black hover:text-[#FF8C00] border-[#FF8C00]"
                  }`}
                  style={{ fontFamily: 'Courier New, monospace' }}
                >
                  <div className="flex items-center justify-center space-x-2">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      {isConnected ? (
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                      ) : (
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
                      )}
                    </svg>
                    <span>{isConnected ? "DISCONNECT" : "CONNECT DEVICE"}</span>
                  </div>
                </button>

                <button
                  onClick={handleFlash}
                  disabled={!canFlash}
                  className={`px-6 py-3 font-semibold transition-all border ${
                    canFlash
                      ? "bg-[#FF8C00] hover:bg-black text-black hover:text-[#FF8C00] border-[#FF8C00]"
                      : "bg-[#0d0d0d] text-[#B0B0B0] border-[#B0B0B0]/30 cursor-not-allowed"
                  }`}
                  style={{ fontFamily: 'Courier New, monospace' }}
                >
                  <div className="flex items-center justify-center space-x-2">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                    </svg>
                    <span>{isFlashing ? "FLASHING..." : "FLASH FIRMWARE"}</span>
                  </div>
                </button>
              </div>

              {/* Progress Bars */}
              {(downloadProgress > 0 || flashProgress > 0) && (
                <div className="space-y-4 mb-6">
                  {downloadProgress > 0 && downloadProgress < 100 && (
                    <ProgressBar
                      percentage={downloadProgress}
                      message="Downloading firmware"
                      variant="blue"
                    />
                  )}
                  {flashProgress > 0 && (
                    <ProgressBar
                      percentage={flashProgress}
                      message="Writing to device"
                      variant="green"
                    />
                  )}
                </div>
              )}

              {/* Log Viewer */}
              <LogViewer logs={logs} />
            </div>
          </div>

          {/* Sidebar */}
          <div className="lg:col-span-1 space-y-6">
            {/* Quick Start Guide */}
            <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6">
              <h2 className="text-lg font-bold text-white mb-4 flex items-center" style={{ fontFamily: 'Courier New, monospace' }}>
                <span className="mr-2">📋</span>
                QUICK START
              </h2>
              <ol className="space-y-3 text-[#B0B0B0] text-sm">
                <li className="flex items-start">
                  <span className="font-bold text-[#FF8C00] mr-2 min-w-[20px]" style={{ fontFamily: 'Courier New, monospace' }}>1.</span>
                  <span style={{ fontFamily: 'Courier New, monospace' }}>SELECT FIRMWARE VERSION</span>
                </li>
                <li className="flex items-start">
                  <span className="font-bold text-[#FF8C00] mr-2 min-w-[20px]" style={{ fontFamily: 'Courier New, monospace' }}>2.</span>
                  <span style={{ fontFamily: 'Courier New, monospace' }}>ENTER BOOTLOADER MODE (BOOT + RESET)</span>
                </li>
                <li className="flex items-start">
                  <span className="font-bold text-[#FF8C00] mr-2 min-w-[20px]" style={{ fontFamily: 'Courier New, monospace' }}>3.</span>
                  <span style={{ fontFamily: 'Courier New, monospace' }}>CLICK &quot;CONNECT DEVICE&quot;</span>
                </li>
                <li className="flex items-start">
                  <span className="font-bold text-[#FF8C00] mr-2 min-w-[20px]" style={{ fontFamily: 'Courier New, monospace' }}>4.</span>
                  <span style={{ fontFamily: 'Courier New, monospace' }}>CLICK &quot;FLASH FIRMWARE&quot;</span>
                </li>
                <li className="flex items-start">
                  <span className="font-bold text-[#FF8C00] mr-2 min-w-[20px]" style={{ fontFamily: 'Courier New, monospace' }}>5.</span>
                  <span style={{ fontFamily: 'Courier New, monospace' }}>WAIT AND RESTART DEVICE</span>
                </li>
              </ol>
            </div>

            {/* Bootloader Mode */}
            <div className="bg-[#0d0d0d] border border-[#FF8C00] p-6">
              <h3 className="text-white font-semibold mb-3 flex items-center" style={{ fontFamily: 'Courier New, monospace' }}>
                <span className="mr-2">💡</span>
                BOOTLOADER MODE
              </h3>
              <p className="text-[#B0B0B0] text-sm mb-3" style={{ fontFamily: 'Courier New, monospace' }}>
                TO ENTER BOOTLOADER MODE:
              </p>
              <ol className="text-[#B0B0B0] text-sm space-y-2">
                <li style={{ fontFamily: 'Courier New, monospace' }}>1. HOLD DOWN <code className="bg-black px-2 py-1 text-[#FF8C00] border border-[#FF8C00]/30">BOOT</code> BUTTON</li>
                <li style={{ fontFamily: 'Courier New, monospace' }}>2. PRESS AND RELEASE <code className="bg-black px-2 py-1 text-[#FF8C00] border border-[#FF8C00]/30">RESET</code></li>
                <li style={{ fontFamily: 'Courier New, monospace' }}>3. RELEASE <code className="bg-black px-2 py-1 text-[#FF8C00] border border-[#FF8C00]/30">BOOT</code> BUTTON</li>
              </ol>
            </div>

            {/* Browser Support */}
            <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6">
              <h3 className="text-white font-semibold mb-3" style={{ fontFamily: 'Courier New, monospace' }}>BROWSER SUPPORT</h3>
              <div className="space-y-2 text-sm">
                <div className="flex items-center justify-between text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                  <span>CHROME 89+</span>
                  <span className="text-[#FF8C00]">✅</span>
                </div>
                <div className="flex items-center justify-between text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                  <span>EDGE 89+</span>
                  <span className="text-[#FF8C00]">✅</span>
                </div>
                <div className="flex items-center justify-between text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                  <span>OPERA 75+</span>
                  <span className="text-[#FF8C00]">✅</span>
                </div>
                <div className="flex items-center justify-between text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                  <span>FIREFOX</span>
                  <span className="text-[#FF8C00]">❌</span>
                </div>
              </div>
            </div>

            {/* Need Help */}
            <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6">
              <h3 className="text-white font-semibold mb-3" style={{ fontFamily: 'Courier New, monospace' }}>NEED HELP?</h3>
              <p className="text-[#B0B0B0] text-sm mb-3" style={{ fontFamily: 'Courier New, monospace' }}>
                HAVING ISSUES? CHECK OUR DOCUMENTATION OR REPORT A PROBLEM.
              </p>
              <a
                href="https://github.com/devkiraa/DeZer0/issues"
                target="_blank"
                rel="noopener noreferrer"
                className="block w-full px-4 py-2 bg-black hover:bg-[#FF8C00] text-[#FF8C00] hover:text-black text-center border border-[#FF8C00] transition text-sm"
                style={{ fontFamily: 'Courier New, monospace' }}
              >
                REPORT ISSUE →
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
