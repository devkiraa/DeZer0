"use client";

import Link from 'next/link';
import { usePathname } from 'next/navigation';

export default function Navigation() {
  const pathname = usePathname();

  const isActive = (path: string) => pathname === path;

  return (
    <nav className="bg-black border-b border-[#FF8C00]/30 sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo and Brand */}
          <div className="flex items-center">
            <Link href="/" className="flex items-center space-x-3 text-white hover:text-[#FF8C00] transition">
              <div className="w-10 h-10 border-2 border-[#FF8C00] rounded flex items-center justify-center">
                <span className="text-[#FF8C00] font-bold text-sm" style={{ fontFamily: 'Courier New, monospace' }}>D0</span>
              </div>
              <span className="font-bold text-xl hidden sm:inline" style={{ fontFamily: 'Courier New, monospace' }}>DEZERO</span>
            </Link>
          </div>

          {/* Navigation Links */}
          <div className="flex items-center space-x-2">
            <Link
              href="/"
              className={`px-4 py-2 text-xs font-bold transition border ${
                isActive('/')
                  ? 'text-black bg-[#FF8C00] border-[#FF8C00]'
                  : 'text-[#B0B0B0] bg-black border-[#FF8C00]/30 hover:text-white hover:border-[#FF8C00]'
              }`}
              style={{ fontFamily: 'Courier New, monospace' }}
            >
              <span className="hidden sm:inline">HOME</span>
              <span className="sm:hidden">🏠</span>
            </Link>
            <Link
              href="/flasher"
              className={`px-4 py-2 text-xs font-bold transition border ${
                isActive('/flasher')
                  ? 'text-black bg-[#FF8C00] border-[#FF8C00]'
                  : 'text-[#B0B0B0] bg-black border-[#FF8C00]/30 hover:text-white hover:border-[#FF8C00]'
              }`}
              style={{ fontFamily: 'Courier New, monospace' }}
            >
              <span className="hidden sm:inline">FLASHER</span>
              <span className="sm:hidden">⚡</span>
            </Link>
            <Link
              href="/marketplace"
              className={`px-4 py-2 text-xs font-bold transition border ${
                isActive('/marketplace')
                  ? 'text-black bg-[#FF8C00] border-[#FF8C00]'
                  : 'text-[#B0B0B0] bg-black border-[#FF8C00]/30 hover:text-white hover:border-[#FF8C00]'
              }`}
              style={{ fontFamily: 'Courier New, monospace' }}
            >
              <span className="hidden sm:inline">TOOLS</span>
              <span className="sm:hidden">🛒</span>
            </Link>
            <Link
              href="/download"
              className={`px-4 py-2 text-xs font-bold transition border ${
                isActive('/download')
                  ? 'text-black bg-[#FF8C00] border-[#FF8C00]'
                  : 'text-[#B0B0B0] bg-black border-[#FF8C00]/30 hover:text-white hover:border-[#FF8C00]'
              }`}
              style={{ fontFamily: 'Courier New, monospace' }}
            >
              <span className="hidden sm:inline">DOWNLOAD</span>
              <span className="sm:hidden">📱</span>
            </Link>
            <a
              href="https://github.com/devkiraa/DeZer0"
              target="_blank"
              rel="noopener noreferrer"
              className="px-3 py-2 text-[#FF8C00] hover:text-white transition"
              aria-label="GitHub"
            >
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path fillRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" clipRule="evenodd" />
              </svg>
            </a>
          </div>
        </div>
      </div>
    </nav>
  );
}
