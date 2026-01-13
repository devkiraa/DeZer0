"use client";

import { useEffect, useRef } from 'react';

interface LogViewerProps {
  logs: string[];
  maxHeight?: string;
}

export default function LogViewer({ logs, maxHeight = '384px' }: LogViewerProps) {
  const logEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    logEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [logs]);

  return (
    <div className="w-full">
      <div className="flex items-center justify-between mb-2">
        <label className="text-sm font-medium text-white" style={{ fontFamily: 'Courier New, monospace' }}>CONSOLE OUTPUT</label>
        <span className="text-xs text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>{logs.length} MESSAGES</span>
      </div>
      <div
        className="w-full bg-black border border-[#FF8C00]/30 overflow-y-auto p-4 font-mono text-sm"
        style={{ maxHeight, fontFamily: 'Courier New, monospace' }}
      >
        {logs.length === 0 ? (
          <div className="text-[#B0B0B0] text-center py-8" style={{ fontFamily: 'Courier New, monospace' }}>
            NO LOGS YET. CONNECT YOUR DEVICE TO BEGIN.
          </div>
        ) : (
          <div className="space-y-1">
            {logs.map((log, index) => {
              const isError = log.toLowerCase().includes('error') || log.toLowerCase().includes('failed');
              const isSuccess = log.toLowerCase().includes('success') || log.toLowerCase().includes('complete');
              const isWarning = log.toLowerCase().includes('warning');
              
              return (
                <div
                  key={index}
                  className={`${
                    isError
                      ? 'text-[#FF8C00]'
                      : isSuccess
                      ? 'text-[#FF8C00]'
                      : isWarning
                      ? 'text-[#FF8C00]'
                      : 'text-[#B0B0B0]'
                  }`}
                  style={{ fontFamily: 'Courier New, monospace' }}
                >
                  <span className="text-[#FF8C00]/50 mr-2">[{index + 1}]</span>
                  {log}
                </div>
              );
            })}
            <div ref={logEndRef} />
          </div>
        )}
      </div>
    </div>
  );
}
