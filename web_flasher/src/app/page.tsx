"use client";

import Link from 'next/link';
import { useState, useEffect } from 'react';

export default function Home() {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  return (
    <div className="min-h-screen bg-black">
      {/* Hero Section */}
      <section className="relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-[#FF8C00]/10 via-black to-black"></div>
        
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 md:py-32">
          <div className="text-center">
            <div className={`transition-all duration-1000 ${mounted ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10'}`}>
              <h1 className="text-5xl md:text-7xl lg:text-8xl font-bold text-[#FF8C00] mb-6" style={{ fontFamily: 'Courier New, monospace' }}>
                DEZERO
              </h1>
              <p className="text-xl md:text-2xl text-white mb-4" style={{ fontFamily: 'Courier New, monospace' }}>
                ESP32 FIRMWARE FLASHER
              </p>
              <p className="text-lg text-[#B0B0B0] mb-10 max-w-2xl mx-auto" style={{ fontFamily: 'Courier New, monospace' }}>
                NO INSTALLATION. NO COMMAND LINE. JUST FLASH.
              </p>
              
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Link
                  href="/flasher"
                  className="px-8 py-4 bg-[#FF8C00] hover:bg-[#ff9d1f] text-black font-bold border-2 border-[#FF8C00] transform hover:scale-105 transition-all"
                  style={{ fontFamily: 'Courier New, monospace' }}
                >
                  🚀 START FLASHING
                </Link>
                <Link
                  href="/download"
                  className="px-8 py-4 bg-black hover:bg-[#0d0d0d] text-[#FF8C00] font-bold border-2 border-[#FF8C00] transform hover:scale-105 transition-all"
                  style={{ fontFamily: 'Courier New, monospace' }}
                >
                  📱 DOWNLOAD APP
                </Link>
                <Link
                  href="/marketplace"
                  className="px-8 py-4 bg-black hover:bg-[#0d0d0d] text-white font-bold border-2 border-[#FF8C00]/30 hover:border-[#FF8C00] transform hover:scale-105 transition-all"
                  style={{ fontFamily: 'Courier New, monospace' }}
                >
                  🛒 BROWSE TOOLS
                </Link>
              </div>
            </div>
          </div>
        </div>

        {/* Animated background elements */}
        <div className="absolute top-20 left-10 w-72 h-72 bg-[#FF8C00]/5 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute bottom-20 right-10 w-96 h-96 bg-[#FF8C00]/5 rounded-full blur-3xl animate-pulse delay-1000"></div>
      </section>

      {/* Features Section */}
      <section className="py-20 bg-black border-t border-[#FF8C00]/30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4" style={{ fontFamily: 'Courier New, monospace' }}>
              WHY CHOOSE DEZERO?
            </h2>
            <p className="text-[#B0B0B0] text-lg" style={{ fontFamily: 'Courier New, monospace' }}>
              THE EASIEST WAY TO MANAGE ESP32 DEVICES
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {/* Feature 1 */}
            <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6 hover:border-[#FF8C00] transition-all">
              <div className="text-4xl mb-4">🌐</div>
              <h3 className="text-xl font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>BROWSER-BASED</h3>
              <p className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>
                NO SOFTWARE INSTALLATION. WORKS IN YOUR BROWSER USING WEB SERIAL API.
              </p>
            </div>

            {/* Feature 2 */}
            <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6 hover:border-[#FF8C00] transition-all">
              <div className="text-4xl mb-4">⚡</div>
              <h3 className="text-xl font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>FAST & EASY</h3>
              <p className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>
                FLASH FIRMWARE IN SECONDS. NO COMPLEX COMMANDS REQUIRED.
              </p>
            </div>

            {/* Feature 3 */}
            <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6 hover:border-[#FF8C00] transition-all">
              <div className="text-4xl mb-4">🔄</div>
              <h3 className="text-xl font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>AUTO UPDATES</h3>
              <p className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>
                AUTOMATICALLY FETCHES LATEST FIRMWARE FROM GITHUB. ALWAYS UP TO DATE.
              </p>
            </div>

            {/* Feature 4 */}
            <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6 hover:border-[#FF8C00] transition-all">
              <div className="text-4xl mb-4">🛒</div>
              <h3 className="text-xl font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>TOOL MARKETPLACE</h3>
              <p className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>
                BROWSE AND INSTALL ESP32 TOOLS FROM OUR CURATED MARKETPLACE.
              </p>
            </div>

            {/* Feature 5 */}
            <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6 hover:border-[#FF8C00] transition-all">
              <div className="text-4xl mb-4">📱</div>
              <h3 className="text-xl font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>RESPONSIVE DESIGN</h3>
              <p className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>
                WORKS ON DESKTOP, TABLET, AND MOBILE. FLASH ANYWHERE, ANYTIME.
              </p>
            </div>

            {/* Feature 6 */}
            <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6 hover:border-[#FF8C00] transition-all">
              <div className="text-4xl mb-4">🔒</div>
              <h3 className="text-xl font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>OPEN SOURCE</h3>
              <p className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>
                FULLY TRANSPARENT. REVIEW CODE, CONTRIBUTE, OR FORK FOR YOUR NEEDS.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* How It Works Section */}
      <section className="py-20 bg-[#0d0d0d] border-t border-[#FF8C00]/30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4" style={{ fontFamily: 'Courier New, monospace' }}>
              HOW IT WORKS
            </h2>
            <p className="text-[#B0B0B0] text-lg" style={{ fontFamily: 'Courier New, monospace' }}>
              GET STARTED IN SIMPLE STEPS
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div className="text-center">
              <div className="w-16 h-16 bg-[#FF8C00] border-2 border-[#FF8C00] flex items-center justify-center text-black text-2xl font-bold mx-auto mb-4" style={{ fontFamily: 'Courier New, monospace' }}>
                1
              </div>
              <h3 className="text-lg font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>SELECT VERSION</h3>
              <p className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>
                CHOOSE FIRMWARE VERSION FROM DROPDOWN
              </p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-black border-2 border-[#FF8C00] flex items-center justify-center text-[#FF8C00] text-2xl font-bold mx-auto mb-4" style={{ fontFamily: 'Courier New, monospace' }}>
                2
              </div>
              <h3 className="text-lg font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>CONNECT DEVICE</h3>
              <p className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>
                CONNECT ESP32 VIA USB, ENTER BOOTLOADER
              </p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-black border-2 border-[#FF8C00] flex items-center justify-center text-[#FF8C00] text-2xl font-bold mx-auto mb-4" style={{ fontFamily: 'Courier New, monospace' }}>
                3
              </div>
              <h3 className="text-lg font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>FLASH FIRMWARE</h3>
              <p className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>
                CLICK FLASH, WATCH REAL-TIME PROGRESS
              </p>
            </div>

            <div className="text-center">
              <div className="w-16 h-16 bg-[#00FF00] border-2 border-[#00FF00] flex items-center justify-center text-black text-2xl font-bold mx-auto mb-4" style={{ fontFamily: 'Courier New, monospace' }}>
                ✓
              </div>
              <h3 className="text-lg font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>DONE!</h3>
              <p className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>
                DEVICE READY WITH LATEST FIRMWARE
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-20 bg-black border-t border-[#FF8C00]/30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
            <div>
              <div className="text-4xl md:text-5xl font-bold text-[#FF8C00] mb-2" style={{ fontFamily: 'Courier New, monospace' }}>100%</div>
              <div className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>FREE & OPEN</div>
            </div>
            <div>
              <div className="text-4xl md:text-5xl font-bold text-[#FF8C00] mb-2" style={{ fontFamily: 'Courier New, monospace' }}>0</div>
              <div className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>INSTALLATION REQUIRED</div>
            </div>
            <div>
              <div className="text-4xl md:text-5xl font-bold text-[#FF8C00] mb-2" style={{ fontFamily: 'Courier New, monospace' }}>FAST</div>
              <div className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>FLASH SPEED</div>
            </div>
            <div>
              <div className="text-4xl md:text-5xl font-bold text-[#FF8C00] mb-2" style={{ fontFamily: 'Courier New, monospace' }}>EASY</div>
              <div className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>USER EXPERIENCE</div>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 bg-gradient-to-r from-[#FF8C00]/20 via-black to-black border-t border-[#FF8C00]/30">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-3xl md:text-4xl font-bold text-white mb-4" style={{ fontFamily: 'Courier New, monospace' }}>
            READY TO GET STARTED?
          </h2>
          <p className="text-xl text-[#B0B0B0] mb-8" style={{ fontFamily: 'Courier New, monospace' }}>
            FLASH YOUR ESP32 IN SECONDS
          </p>
          <Link
            href="/flasher"
            className="inline-block px-10 py-5 bg-[#FF8C00] hover:bg-[#ff9d1f] text-black text-lg font-bold border-2 border-[#FF8C00] transform hover:scale-105 transition-all"
            style={{ fontFamily: 'Courier New, monospace' }}
          >
            LAUNCH WEB FLASHER →
          </Link>
        </div>
      </section>

      {/* Browser Compatibility */}
      <section className="py-12 bg-[#0d0d0d] border-t border-[#FF8C00]/30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-8">
            <h3 className="text-xl font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>BROWSER COMPATIBILITY</h3>
            <p className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>REQUIRES WEB SERIAL API SUPPORT</p>
          </div>
          <div className="flex justify-center items-center space-x-8 text-[#B0B0B0]">
            <div className="text-center">
              <div className="text-3xl mb-2">✅</div>
              <div className="text-sm" style={{ fontFamily: 'Courier New, monospace' }}>CHROME 89+</div>
            </div>
            <div className="text-center">
              <div className="text-3xl mb-2">✅</div>
              <div className="text-sm" style={{ fontFamily: 'Courier New, monospace' }}>EDGE 89+</div>
            </div>
            <div className="text-center">
              <div className="text-3xl mb-2">✅</div>
              <div className="text-sm" style={{ fontFamily: 'Courier New, monospace' }}>OPERA 75+</div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
