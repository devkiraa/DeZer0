"use client";

interface ProgressBarProps {
  percentage: number;
  message?: string;
  variant?: 'blue' | 'green' | 'yellow';
}

export default function ProgressBar({ percentage, message, variant = 'blue' }: ProgressBarProps) {
  return (
    <div className="w-full">
      <div className="flex items-center justify-between mb-2">
        <span className="text-sm font-medium text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
          {message ? message.toUpperCase() : 'PROGRESS'}
        </span>
        <span className="text-sm font-semibold text-[#FF8C00]" style={{ fontFamily: 'Courier New, monospace' }}>
          {percentage}%
        </span>
      </div>
      <div className="w-full bg-[#0d0d0d] border border-[#FF8C00]/30 h-3 overflow-hidden">
        <div
          className="h-full bg-[#FF8C00] transition-all duration-300 ease-out"
          style={{ width: `${percentage}%` }}
        >
          <div className="h-full w-full animate-pulse bg-white opacity-20"></div>
        </div>
      </div>
    </div>
  );
}
