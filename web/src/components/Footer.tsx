"use client";

export default function Footer() {
  return (
    <footer className="bg-black border-t border-[#FF8C00]/30 mt-auto">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* About */}
          <div>
            <h3 className="text-white font-bold mb-3" style={{ fontFamily: 'Courier New, monospace' }}>DEZERO</h3>
            <p className="text-[#B0B0B0] text-sm" style={{ fontFamily: 'Courier New, monospace' }}>
              OPEN-SOURCE ESP32 FIRMWARE FLASHING AND TOOL MANAGEMENT PLATFORM.
            </p>
          </div>

          {/* Quick Links */}
          <div>
            <h3 className="text-white font-bold mb-3" style={{ fontFamily: 'Courier New, monospace' }}>QUICK LINKS</h3>
            <ul className="space-y-2 text-sm">
              <li>
                <a href="/" className="text-[#B0B0B0] hover:text-[#FF8C00] transition" style={{ fontFamily: 'Courier New, monospace' }}>
                  HOME
                </a>
              </li>
              <li>
                <a href="/flasher" className="text-[#B0B0B0] hover:text-[#FF8C00] transition" style={{ fontFamily: 'Courier New, monospace' }}>
                  FLASHER
                </a>
              </li>
              <li>
                <a href="/marketplace" className="text-[#B0B0B0] hover:text-[#FF8C00] transition" style={{ fontFamily: 'Courier New, monospace' }}>
                  TOOLS
                </a>
              </li>
              <li>
                <a href="/download" className="text-[#B0B0B0] hover:text-[#FF8C00] transition" style={{ fontFamily: 'Courier New, monospace' }}>
                  DOWNLOAD
                </a>
              </li>
            </ul>
          </div>

          {/* Resources */}
          <div>
            <h3 className="text-white font-bold mb-3" style={{ fontFamily: 'Courier New, monospace' }}>RESOURCES</h3>
            <ul className="space-y-2 text-sm">
              <li>
                <a
                  href="https://github.com/devkiraa/DeZer0"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-[#B0B0B0] hover:text-[#FF8C00] transition"
                  style={{ fontFamily: 'Courier New, monospace' }}
                >
                  GITHUB REPO
                </a>
              </li>
              <li>
                <a
                  href="https://try-nex.vercel.app"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-[#B0B0B0] hover:text-[#FF8C00] transition"
                  style={{ fontFamily: 'Courier New, monospace' }}
                >
                  NEX REGISTRY
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/devkiraa/DeZer0/issues"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-[#B0B0B0] hover:text-[#FF8C00] transition"
                  style={{ fontFamily: 'Courier New, monospace' }}
                >
                  REPORT ISSUES
                </a>
              </li>
            </ul>
          </div>

          {/* Community */}
          <div>
            <h3 className="text-white font-bold mb-3" style={{ fontFamily: 'Courier New, monospace' }}>COMMUNITY</h3>
            <ul className="space-y-2 text-sm">
              <li>
                <a
                  href="https://github.com/devkiraa/DeZer0/discussions"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-[#B0B0B0] hover:text-[#FF8C00] transition"
                  style={{ fontFamily: 'Courier New, monospace' }}
                >
                  DISCUSSIONS
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/devkiraa/DeZer0/blob/main/CONTRIBUTING.md"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-[#B0B0B0] hover:text-[#FF8C00] transition"
                  style={{ fontFamily: 'Courier New, monospace' }}
                >
                  CONTRIBUTING
                </a>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-8 pt-8 border-t border-[#FF8C00]/30 text-center text-[#B0B0B0] text-sm">
          <p style={{ fontFamily: 'Courier New, monospace' }}>© 2025 DEZERO. OPEN SOURCE UNDER MIT LICENSE.</p>
        </div>
      </div>
    </footer>
  );
}
