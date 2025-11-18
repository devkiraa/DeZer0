"use client";

import { useState } from 'react';
import { GitHubRelease } from '@/types';
import { githubService } from '@/services/githubService';

interface ReleaseSelectProps {
  onReleaseSelect: (release: GitHubRelease) => void;
  selectedRelease: GitHubRelease | null;
}

export default function ReleaseSelect({ onReleaseSelect, selectedRelease }: ReleaseSelectProps) {
  const [releases, setReleases] = useState<GitHubRelease[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isOpen, setIsOpen] = useState(false);

  const fetchReleases = async () => {
    if (releases.length > 0) {
      setIsOpen(!isOpen);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      const fetchedReleases = await githubService.getAllReleases();
      setReleases(fetchedReleases);
      if (fetchedReleases.length > 0 && !selectedRelease) {
        onReleaseSelect(fetchedReleases[0]);
      }
      setIsOpen(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch releases');
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  return (
    <div className="w-full">
      <label className="block text-sm font-medium text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>
        SELECT FIRMWARE VERSION
      </label>
      <div className="relative">
        <button
          onClick={fetchReleases}
          disabled={loading}
          className="w-full px-4 py-3 text-left bg-black border border-[#FF8C00]/30 hover:border-[#FF8C00] focus:outline-none focus:ring-2 focus:ring-[#FF8C00] focus:border-transparent transition-all disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <div className="flex items-center justify-between">
            <div>
              {selectedRelease ? (
                <div>
                  <div className="font-semibold text-white" style={{ fontFamily: 'Courier New, monospace' }}>{selectedRelease.name.toUpperCase()}</div>
                  <div className="text-sm text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>{selectedRelease.tag_name}</div>
                </div>
              ) : (
                <span className="text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                  {loading ? 'LOADING RELEASES...' : 'CLICK TO SELECT VERSION'}
                </span>
              )}
            </div>
            <svg
              className={`w-5 h-5 text-[#FF8C00] transition-transform ${isOpen ? 'rotate-180' : ''}`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
            </svg>
          </div>
        </button>

        {isOpen && releases.length > 0 && (
          <div className="absolute z-10 w-full mt-2 bg-[#0d0d0d] border border-[#FF8C00]/30 shadow-lg max-h-96 overflow-y-auto">
            {releases.map((release) => (
              <button
                key={release.id}
                onClick={() => {
                  onReleaseSelect(release);
                  setIsOpen(false);
                }}
                className={`w-full px-4 py-3 text-left hover:bg-black transition-colors border-b border-[#FF8C00]/30 last:border-b-0 ${
                  selectedRelease?.id === release.id ? 'bg-black border-[#FF8C00]' : ''
                }`}
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="font-semibold text-white" style={{ fontFamily: 'Courier New, monospace' }}>{release.name.toUpperCase()}</div>
                    <div className="text-sm text-[#B0B0B0] mt-1" style={{ fontFamily: 'Courier New, monospace' }}>{release.tag_name}</div>
                    <div className="text-xs text-[#B0B0B0] mt-1" style={{ fontFamily: 'Courier New, monospace' }}>
                      RELEASED: {formatDate(release.published_at).toUpperCase()}
                    </div>
                  </div>
                  {selectedRelease?.id === release.id && (
                    <svg className="w-5 h-5 text-[#FF8C00]" fill="currentColor" viewBox="0 0 20 20">
                      <path
                        fillRule="evenodd"
                        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                        clipRule="evenodd"
                      />
                    </svg>
                  )}
                </div>
              </button>
            ))}
          </div>
        )}
      </div>

      {error && (
        <div className="mt-2 p-3 bg-[#0d0d0d] border border-[#FF8C00]">
          <p className="text-sm text-[#FF8C00]" style={{ fontFamily: 'Courier New, monospace' }}>{error.toUpperCase()}</p>
        </div>
      )}
    </div>
  );
}
