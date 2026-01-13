"use client";

import { useState, useEffect } from 'react';
import { githubService } from '@/services/githubService';
import { GitHubRelease } from '@/types';

interface AppAsset {
  name: string;
  url: string;
  size: number;
  downloadCount: number;
  publishedAt: string;
  version: string;
}

export default function DownloadPage() {
  const [releases, setReleases] = useState<GitHubRelease[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedRelease, setSelectedRelease] = useState<GitHubRelease | null>(null);

  useEffect(() => {
    fetchReleases();
  }, []);

  const fetchReleases = async () => {
    try {
      setLoading(true);
      const allReleases = await githubService.getAllReleases();
      // Filter releases that have APK files
      const releasesWithApk = allReleases.filter(release => 
        release.assets.some(asset => asset.name.toLowerCase().endsWith('.apk'))
      );
      setReleases(releasesWithApk);
      if (releasesWithApk.length > 0) {
        setSelectedRelease(releasesWithApk[0]);
      }
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch releases');
    } finally {
      setLoading(false);
    }
  };

  const getAppAssets = (release: GitHubRelease): AppAsset[] => {
    return release.assets
      .filter(asset => asset.name.toLowerCase().endsWith('.apk'))
      .map(asset => ({
        name: asset.name,
        url: asset.browser_download_url,
        size: asset.size,
        downloadCount: asset.download_count,
        publishedAt: release.published_at,
        version: release.tag_name,
      }));
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  const handleDownload = (url: string, filename: string) => {
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-black flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#FF8C00] mx-auto mb-4"></div>
          <p className="text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>LOADING RELEASES...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-black flex items-center justify-center">
        <div className="text-center max-w-md">
          <div className="text-[#FF8C00] text-5xl mb-4">⚠️</div>
          <h2 className="text-2xl font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>ERROR LOADING RELEASES</h2>
          <p className="text-[#B0B0B0] mb-4" style={{ fontFamily: 'Courier New, monospace' }}>{error.toUpperCase()}</p>
          <button
            onClick={fetchReleases}
            className="bg-[#FF8C00] hover:bg-black text-black hover:text-[#FF8C00] border border-[#FF8C00] px-6 py-2 transition"
            style={{ fontFamily: 'Courier New, monospace' }}
          >
            RETRY
          </button>
        </div>
      </div>
    );
  }

  if (releases.length === 0) {
    return (
      <div className="min-h-screen bg-black flex items-center justify-center">
        <div className="text-center max-w-md">
          <div className="text-[#B0B0B0] text-5xl mb-4">📱</div>
          <h2 className="text-2xl font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>NO APP RELEASES AVAILABLE</h2>
          <p className="text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>CHECK BACK LATER FOR MOBILE APP RELEASES.</p>
        </div>
      </div>
    );
  }

  const appAssets = selectedRelease ? getAppAssets(selectedRelease) : [];

  return (
    <div className="min-h-screen bg-black py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="inline-flex items-center justify-center w-20 h-20 bg-[#0d0d0d] border border-[#FF8C00] mb-6">
            <span className="text-[#FF8C00] text-3xl">📱</span>
          </div>
          <h1 className="text-4xl sm:text-5xl font-bold text-white mb-4" style={{ fontFamily: 'Courier New, monospace' }}>
            DOWNLOAD DEZERO APP
          </h1>
          <p className="text-xl text-[#B0B0B0] max-w-2xl mx-auto" style={{ fontFamily: 'Courier New, monospace' }}>
            GET THE OFFICIAL DEZERO MOBILE APPLICATION FOR ANDROID. CONTROL YOUR ESP32 DEVICE ON THE GO.
          </p>
        </div>

        {/* Version Selector */}
        <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6 mb-8">
          <label className="block text-sm font-medium text-white mb-3" style={{ fontFamily: 'Courier New, monospace' }}>
            SELECT VERSION
          </label>
          <select
            value={selectedRelease?.id || ''}
            onChange={(e) => {
              const release = releases.find(r => r.id.toString() === e.target.value);
              setSelectedRelease(release || null);
            }}
            className="w-full bg-black border border-[#FF8C00]/30 text-white px-4 py-3 focus:outline-none focus:ring-2 focus:ring-[#FF8C00] focus:border-transparent"
            style={{ fontFamily: 'Courier New, monospace' }}
          >
            {releases.map((release) => (
              <option key={release.id} value={release.id}>
                {release.tag_name} - {formatDate(release.published_at)}
              </option>
            ))}
          </select>
        </div>

        {/* Release Info */}
        {selectedRelease && (
          <div className="grid md:grid-cols-3 gap-6 mb-8">
            <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6">
              <div className="text-[#B0B0B0] text-sm mb-1" style={{ fontFamily: 'Courier New, monospace' }}>VERSION</div>
              <div className="text-2xl font-bold text-[#FF8C00]" style={{ fontFamily: 'Courier New, monospace' }}>{selectedRelease.tag_name}</div>
            </div>
            <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6">
              <div className="text-[#B0B0B0] text-sm mb-1" style={{ fontFamily: 'Courier New, monospace' }}>RELEASED</div>
              <div className="text-2xl font-bold text-[#FF8C00]" style={{ fontFamily: 'Courier New, monospace' }}>{formatDate(selectedRelease.published_at).toUpperCase()}</div>
            </div>
            <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6">
              <div className="text-[#B0B0B0] text-sm mb-1" style={{ fontFamily: 'Courier New, monospace' }}>DOWNLOADS</div>
              <div className="text-2xl font-bold text-[#FF8C00]" style={{ fontFamily: 'Courier New, monospace' }}>
                {appAssets.reduce((sum, asset) => sum + asset.downloadCount, 0).toLocaleString()}
              </div>
            </div>
          </div>
        )}

        {/* Download Cards */}
        <div className="space-y-4 mb-12">
          {appAssets.map((asset, index) => (
            <div
              key={index}
              className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6 hover:border-[#FF8C00] transition"
            >
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <div className="w-12 h-12 bg-[#0d0d0d] border border-[#FF8C00] flex items-center justify-center">
                      <span className="text-[#FF8C00] text-xl">🤖</span>
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-white" style={{ fontFamily: 'Courier New, monospace' }}>{asset.name.toUpperCase()}</h3>
                      <p className="text-sm text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                        {githubService.formatFileSize(asset.size)} • VERSION {asset.version}
                      </p>
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-2 text-xs text-[#B0B0B0] ml-15">
                    <span className="bg-black border border-[#FF8C00]/30 px-2 py-1" style={{ fontFamily: 'Courier New, monospace' }}>ANDROID APK</span>
                    <span className="bg-black border border-[#FF8C00]/30 px-2 py-1" style={{ fontFamily: 'Courier New, monospace' }}>
                      {asset.downloadCount.toLocaleString()} DOWNLOADS
                    </span>
                  </div>
                </div>
                <button
                  onClick={() => handleDownload(asset.url, asset.name)}
                  className="bg-[#FF8C00] hover:bg-black text-black hover:text-[#FF8C00] border border-[#FF8C00] px-6 py-3 font-medium transition flex items-center justify-center gap-2 whitespace-nowrap"
                  style={{ fontFamily: 'Courier New, monospace' }}
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
                  </svg>
                  DOWNLOAD APK
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* Installation Instructions */}
        <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-8">
          <h2 className="text-2xl font-bold text-white mb-6" style={{ fontFamily: 'Courier New, monospace' }}>INSTALLATION INSTRUCTIONS</h2>
          <div className="space-y-6">
            <div className="flex gap-4">
              <div className="flex-shrink-0 w-8 h-8 bg-[#FF8C00] flex items-center justify-center text-black font-bold" style={{ fontFamily: 'Courier New, monospace' }}>
                1
              </div>
              <div>
                <h3 className="text-lg font-semibold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>ENABLE UNKNOWN SOURCES</h3>
                <p className="text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                  GO TO SETTINGS → SECURITY → ENABLE &quot;INSTALL FROM UNKNOWN SOURCES&quot; OR &quot;ALLOW FROM THIS SOURCE&quot; FOR YOUR BROWSER.
                </p>
              </div>
            </div>
            <div className="flex gap-4">
              <div className="flex-shrink-0 w-8 h-8 bg-[#FF8C00] flex items-center justify-center text-black font-bold" style={{ fontFamily: 'Courier New, monospace' }}>
                2
              </div>
              <div>
                <h3 className="text-lg font-semibold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>DOWNLOAD THE APK</h3>
                <p className="text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                  CLICK THE &quot;DOWNLOAD APK&quot; BUTTON ABOVE TO DOWNLOAD THE LATEST VERSION OF DEZERO APP TO YOUR DEVICE.
                </p>
              </div>
            </div>
            <div className="flex gap-4">
              <div className="flex-shrink-0 w-8 h-8 bg-[#FF8C00] flex items-center justify-center text-black font-bold" style={{ fontFamily: 'Courier New, monospace' }}>
                3
              </div>
              <div>
                <h3 className="text-lg font-semibold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>INSTALL THE APP</h3>
                <p className="text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                  OPEN THE DOWNLOADED APK FILE AND FOLLOW THE INSTALLATION PROMPTS. YOU MAY NEED TO GRANT INSTALLATION PERMISSIONS.
                </p>
              </div>
            </div>
            <div className="flex gap-4">
              <div className="flex-shrink-0 w-8 h-8 bg-[#FF8C00] flex items-center justify-center text-black font-bold" style={{ fontFamily: 'Courier New, monospace' }}>
                4
              </div>
              <div>
                <h3 className="text-lg font-semibold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>LAUNCH AND CONNECT</h3>
                <p className="text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                  OPEN THE DEZERO APP, GRANT NECESSARY PERMISSIONS, AND CONNECT TO YOUR ESP32 DEVICE VIA BLUETOOTH.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Release Notes */}
        {selectedRelease && selectedRelease.body && (
          <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-8 mt-8">
            <h2 className="text-2xl font-bold text-white mb-4" style={{ fontFamily: 'Courier New, monospace' }}>RELEASE NOTES</h2>
            <div className="prose prose-invert max-w-none">
              <pre className="text-[#B0B0B0] whitespace-pre-wrap text-sm" style={{ fontFamily: 'Courier New, monospace' }}>
                {selectedRelease.body}
              </pre>
            </div>
          </div>
        )}

        {/* System Requirements */}
        <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-8 mt-8">
          <h2 className="text-2xl font-bold text-white mb-6" style={{ fontFamily: 'Courier New, monospace' }}>SYSTEM REQUIREMENTS</h2>
          <div className="grid sm:grid-cols-2 gap-6">
            <div>
              <h3 className="text-lg font-semibold text-white mb-3" style={{ fontFamily: 'Courier New, monospace' }}>MINIMUM REQUIREMENTS</h3>
              <ul className="space-y-2 text-[#B0B0B0]">
                <li className="flex items-start gap-2">
                  <span className="text-[#FF8C00] mt-1">✓</span>
                  <span style={{ fontFamily: 'Courier New, monospace' }}>ANDROID 6.0 (MARSHMALLOW) OR HIGHER</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-[#FF8C00] mt-1">✓</span>
                  <span style={{ fontFamily: 'Courier New, monospace' }}>BLUETOOTH 4.0 (BLE) SUPPORT</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-[#FF8C00] mt-1">✓</span>
                  <span style={{ fontFamily: 'Courier New, monospace' }}>50 MB FREE STORAGE SPACE</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-[#FF8C00] mt-1">✓</span>
                  <span style={{ fontFamily: 'Courier New, monospace' }}>LOCATION PERMISSION FOR BLE SCANNING</span>
                </li>
              </ul>
            </div>
            <div>
              <h3 className="text-lg font-semibold text-white mb-3" style={{ fontFamily: 'Courier New, monospace' }}>RECOMMENDED</h3>
              <ul className="space-y-2 text-[#B0B0B0]">
                <li className="flex items-start gap-2">
                  <span className="text-[#FF8C00] mt-1">✓</span>
                  <span style={{ fontFamily: 'Courier New, monospace' }}>ANDROID 8.0 (OREO) OR HIGHER</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-[#FF8C00] mt-1">✓</span>
                  <span style={{ fontFamily: 'Courier New, monospace' }}>BLUETOOTH 5.0 FOR BETTER RANGE</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-[#FF8C00] mt-1">✓</span>
                  <span style={{ fontFamily: 'Courier New, monospace' }}>100 MB FREE STORAGE FOR TOOLS</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-[#FF8C00] mt-1">✓</span>
                  <span style={{ fontFamily: 'Courier New, monospace' }}>WIFI FOR MARKETPLACE ACCESS</span>
                </li>
              </ul>
            </div>
          </div>
        </div>

        {/* FAQ */}
        <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-8 mt-8">
          <h2 className="text-2xl font-bold text-white mb-6" style={{ fontFamily: 'Courier New, monospace' }}>FREQUENTLY ASKED QUESTIONS</h2>
          <div className="space-y-6">
            <div>
              <h3 className="text-lg font-semibold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>IS THE APP SAFE TO INSTALL?</h3>
              <p className="text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                YES, THE APP IS COMPLETELY SAFE. IT&apos;S BUILT BY THE OFFICIAL DEZERO TEAM AND HOSTED ON GITHUB. 
                YOU MAY SEE A WARNING BECAUSE IT&apos;S NOT FROM GOOGLE PLAY STORE, BUT THAT&apos;S NORMAL FOR SIDELOADED APPS.
              </p>
            </div>
            <div>
              <h3 className="text-lg font-semibold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>WILL I RECEIVE AUTOMATIC UPDATES?</h3>
              <p className="text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                THE APP WILL NOTIFY YOU WHEN NEW VERSIONS ARE AVAILABLE, BUT YOU&apos;LL NEED TO MANUALLY DOWNLOAD 
                AND INSTALL UPDATES FROM THIS PAGE.
              </p>
            </div>
            <div>
              <h3 className="text-lg font-semibold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>WHY ISN&apos;T IT ON GOOGLE PLAY STORE?</h3>
              <p className="text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                WE&apos;RE FOCUSED ON RAPID DEVELOPMENT AND COMMUNITY FEEDBACK. DIRECT DISTRIBUTION ALLOWS US TO 
                RELEASE UPDATES FASTER WITHOUT APP STORE REVIEW DELAYS.
              </p>
            </div>
            <div>
              <h3 className="text-lg font-semibold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>WHAT PERMISSIONS DOES THE APP NEED?</h3>
              <p className="text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                THE APP REQUIRES BLUETOOTH (FOR ESP32 COMMUNICATION), LOCATION (REQUIRED BY ANDROID FOR BLE SCANNING), 
                AND STORAGE (FOR DOWNLOADING TOOLS) PERMISSIONS.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
