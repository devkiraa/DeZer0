"use client";

import { useState, useEffect } from 'react';
import { ToolPackage } from '@/types/marketplace';
import { marketplaceService } from '@/services/marketplaceService';

const INITIAL_LOAD = 9;
const LOAD_MORE_COUNT = 6;

export default function MarketplacePage() {
  const [tools, setTools] = useState<ToolPackage[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedTool, setSelectedTool] = useState<ToolPackage | null>(null);
  const [totalCount, setTotalCount] = useState(0);
  const [hasMoreToLoad, setHasMoreToLoad] = useState(true);

  useEffect(() => {
    loadInitialTools();
  }, []);

  const loadInitialTools = async () => {
    try {
      setLoading(true);
      const [fetchedTools, total] = await Promise.all([
        marketplaceService.fetchTools(INITIAL_LOAD, 0),
        marketplaceService.getTotalToolCount()
      ]);
      setTools(fetchedTools);
      setTotalCount(total);
      setHasMoreToLoad(fetchedTools.length < total);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load tools');
    } finally {
      setLoading(false);
    }
  };

  const loadMoreTools = async () => {
    if (loadingMore || !hasMoreToLoad) return;

    try {
      setLoadingMore(true);
      const currentOffset = tools.length;
      const newTools = await marketplaceService.fetchTools(LOAD_MORE_COUNT, currentOffset);
      const updatedTools = [...tools, ...newTools];
      setTools(updatedTools);
      setHasMoreToLoad(updatedTools.length < totalCount);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load more tools');
    } finally {
      setLoadingMore(false);
    }
  };

  const categories = ['All', ...Array.from(new Set(tools.map(t => t.category)))];

  const filteredTools = tools.filter(tool => {
    const matchesCategory = selectedCategory === 'All' || tool.category === selectedCategory;
    const matchesSearch = tool.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      tool.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      tool.tags?.some(tag => tag.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchesCategory && matchesSearch;
  });

  const showLoadMore = !loading && !error && hasMoreToLoad && filteredTools.length === tools.length;

  const SkeletonCard = () => (
    <div className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6 animate-pulse">
      <div className="flex items-start justify-between mb-4">
        <div className="flex items-center space-x-3">
          <div className="w-12 h-12 bg-[#1a1a1a] rounded"></div>
          <div>
            <div className="h-5 w-32 bg-[#1a1a1a] rounded mb-2"></div>
            <div className="h-4 w-16 bg-[#1a1a1a] rounded"></div>
          </div>
        </div>
      </div>
      <div className="space-y-2 mb-4">
        <div className="h-4 bg-[#1a1a1a] rounded w-full"></div>
        <div className="h-4 bg-[#1a1a1a] rounded w-5/6"></div>
        <div className="h-4 bg-[#1a1a1a] rounded w-4/6"></div>
      </div>
      <div className="flex items-center justify-between mb-4">
        <div className="h-4 w-24 bg-[#1a1a1a] rounded"></div>
        <div className="h-6 w-20 bg-[#1a1a1a] rounded"></div>
      </div>
      <div className="flex gap-2">
        <div className="h-6 w-16 bg-[#1a1a1a] rounded"></div>
        <div className="h-6 w-20 bg-[#1a1a1a] rounded"></div>
        <div className="h-6 w-18 bg-[#1a1a1a] rounded"></div>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-black">
      {/* Header */}
      <div className="bg-[#0d0d0d] border-b border-[#FF8C00]/30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <h1 className="text-3xl md:text-4xl font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>
            ⚡ NEX TOOL MARKETPLACE
          </h1>
          <p className="text-[#B0B0B0] text-lg" style={{ fontFamily: 'Courier New, monospace' }}>
            POWERED BY NEX - THE AI-NATIVE PACKAGE MANAGER
          </p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Search and Filter */}
        <div className="mb-8 space-y-4">
          {/* Search Bar */}
          <div className="relative">
            <input
              type="text"
              placeholder="SEARCH TOOLS..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full px-4 py-3 pl-12 bg-[#0d0d0d] border border-[#FF8C00]/30 text-white placeholder-[#B0B0B0] focus:outline-none focus:ring-2 focus:ring-[#FF8C00] focus:border-transparent"
              style={{ fontFamily: 'Courier New, monospace' }}
            />
            <svg
              className="absolute left-4 top-1/2 transform -translate-y-1/2 w-5 h-5 text-[#FF8C00]"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>

          {/* Category Filter */}
          <div className="flex flex-wrap gap-2">
            {categories.map((category) => (
              <button
                key={category}
                onClick={() => setSelectedCategory(category)}
                className={`px-4 py-2 font-medium transition-all ${selectedCategory === category
                    ? 'bg-[#FF8C00] text-black border border-[#FF8C00]'
                    : 'bg-black text-[#FF8C00] hover:bg-[#0d0d0d] border border-[#FF8C00]/30'
                  }`}
                style={{ fontFamily: 'Courier New, monospace' }}
              >
                {category === 'All' ? '📦 ALL' : `${marketplaceService.getCategoryIcon(category)} ${category.toUpperCase()}`}
              </button>
            ))}
          </div>
        </div>

        {/* Loading State */}
        {loading && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[...Array(9)].map((_, idx) => (
              <SkeletonCard key={idx} />
            ))}
          </div>
        )}

        {/* Error State */}
        {error && (
          <div className="bg-[#0d0d0d] border border-[#FF8C00] p-6 text-center">
            <p className="text-[#FF8C00] mb-4" style={{ fontFamily: 'Courier New, monospace' }}>{error.toUpperCase()}</p>
            <button
              onClick={loadInitialTools}
              className="px-6 py-2 bg-[#FF8C00] hover:bg-black text-black hover:text-[#FF8C00] border border-[#FF8C00] transition"
              style={{ fontFamily: 'Courier New, monospace' }}
            >
              RETRY
            </button>
          </div>
        )}

        {/* Tools Grid */}
        {!loading && !error && (
          <>
            <div className="mb-4 text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
              SHOWING {tools.length} OF {totalCount} TOOLS {filteredTools.length < tools.length ? `(${filteredTools.length} FILTERED)` : ''}
            </div>

            {filteredTools.length === 0 ? (
              <div className="text-center py-20">
                <div className="text-6xl mb-4">🔍</div>
                <p className="text-[#B0B0B0] text-lg" style={{ fontFamily: 'Courier New, monospace' }}>NO TOOLS FOUND MATCHING YOUR CRITERIA</p>
              </div>
            ) : (
              <>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {filteredTools.map((tool) => (
                    <div
                      key={tool.id}
                      onClick={() => setSelectedTool(tool)}
                      className="bg-[#0d0d0d] border border-[#FF8C00]/30 p-6 hover:border-[#FF8C00] transition-all group cursor-pointer"
                    >
                      {/* Tool Header */}
                      <div className="flex items-start justify-between mb-4">
                        <div className="flex items-center space-x-3">
                          <div className="text-3xl">{marketplaceService.getCategoryIcon(tool.category)}</div>
                          <div>
                            <h3 className="text-lg font-semibold text-white group-hover:text-[#FF8C00] transition" style={{ fontFamily: 'Courier New, monospace' }}>
                              {tool.name.toUpperCase()}
                            </h3>
                            <p className="text-sm text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>V{tool.version}</p>
                          </div>
                        </div>
                      </div>

                      {/* Description */}
                      <p className="text-[#B0B0B0] text-sm mb-4 line-clamp-3" style={{ fontFamily: 'Courier New, monospace' }}>
                        {tool.description.toUpperCase()}
                      </p>

                      {/* Meta Info */}
                      <div className="flex items-center justify-between text-sm text-[#B0B0B0] mb-4">
                        <span style={{ fontFamily: 'Courier New, monospace' }}>BY {tool.author.toUpperCase()}</span>
                        <span className="px-2 py-1 bg-black border border-[#FF8C00]/30 text-xs" style={{ fontFamily: 'Courier New, monospace' }}>
                          {tool.category.toUpperCase()}
                        </span>
                      </div>

                      {/* Tags */}
                      {tool.tags && tool.tags.length > 0 && (
                        <div className="flex flex-wrap gap-2">
                          {tool.tags.slice(0, 3).map((tag, idx) => (
                            <span
                              key={idx}
                              className="px-2 py-1 bg-[#0d0d0d] text-[#FF8C00] text-xs border border-[#FF8C00]/30"
                              style={{ fontFamily: 'Courier New, monospace' }}
                            >
                              {tag.toUpperCase()}
                            </span>
                          ))}
                        </div>
                      )}
                    </div>
                  ))}
                </div>

                {/* Load More Button */}
                {showLoadMore && (
                  <div className="mt-8 text-center">
                    <button
                      onClick={loadMoreTools}
                      disabled={loadingMore}
                      className="px-8 py-3 bg-[#FF8C00] hover:bg-black text-black hover:text-[#FF8C00] border border-[#FF8C00] transition font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                      style={{ fontFamily: 'Courier New, monospace' }}
                    >
                      {loadingMore ? 'LOADING...' : 'LOAD MORE TOOLS'}
                    </button>
                  </div>
                )}
              </>
            )}
          </>
        )}

        {/* Info Box */}
        <div className="mt-12 bg-[#0d0d0d] border border-[#FF8C00] p-6">
          <h3 className="text-white font-semibold mb-2 flex items-center" style={{ fontFamily: 'Courier New, monospace' }}>
            <span className="mr-2">⚡</span>
            INSTALL WITH NEX CLI
          </h3>
          <div className="text-[#B0B0B0] space-y-3 text-sm" style={{ fontFamily: 'Courier New, monospace' }}>
            <p>1. INSTALL NEX (IF NOT ALREADY INSTALLED):</p>
            <pre className="bg-black border border-[#FF8C00]/30 p-3 text-[#FF8C00] overflow-x-auto">
              iwr https://raw.githubusercontent.com/nexhq/nex/main/cli/install.ps1 | iex
            </pre>
            <p>2. SEARCH AND INSTALL TOOLS:</p>
            <pre className="bg-black border border-[#FF8C00]/30 p-3 text-[#FF8C00] overflow-x-auto">
              nex search &quot;tool name&quot;{"\n"}nex install author.package-name
            </pre>
            <p>3. RUN THE TOOL:</p>
            <pre className="bg-black border border-[#FF8C00]/30 p-3 text-[#FF8C00] overflow-x-auto">
              nex run package-name --help
            </pre>
          </div>
        </div>
      </div>

      {/* Tool Detail Modal */}
      {selectedTool && (
        <div
          className="fixed inset-0 bg-black/80 flex items-center justify-center p-4 z-50"
          onClick={() => setSelectedTool(null)}
        >
          <div
            className="bg-[#0d0d0d] border border-[#FF8C00] max-w-3xl w-full max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <div className="sticky top-0 bg-[#0d0d0d] border-b border-[#FF8C00]/30 p-6 flex items-start justify-between">
              <div className="flex items-center space-x-4">
                <div className="text-4xl">{marketplaceService.getCategoryIcon(selectedTool.category)}</div>
                <div>
                  <h2 className="text-2xl font-bold text-white" style={{ fontFamily: 'Courier New, monospace' }}>
                    {selectedTool.name.toUpperCase()}
                  </h2>
                  <p className="text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                    V{selectedTool.version} • BY {selectedTool.author.toUpperCase()}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setSelectedTool(null)}
                className="text-[#FF8C00] hover:text-white text-2xl leading-none"
              >
                ×
              </button>
            </div>

            {/* Content */}
            <div className="p-6 space-y-6">
              {/* Description */}
              <div>
                <h3 className="text-lg font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>
                  DESCRIPTION
                </h3>
                <p className="text-[#B0B0B0]" style={{ fontFamily: 'Courier New, monospace' }}>
                  {selectedTool.description}
                </p>
              </div>

              {/* Category */}
              <div>
                <h3 className="text-lg font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>
                  CATEGORY
                </h3>
                <span className="inline-block px-3 py-1 bg-black border border-[#FF8C00]/30 text-[#FF8C00]" style={{ fontFamily: 'Courier New, monospace' }}>
                  {selectedTool.category.toUpperCase()}
                </span>
              </div>

              {/* Tags */}
              {selectedTool.tags && selectedTool.tags.length > 0 && (
                <div>
                  <h3 className="text-lg font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>
                    TAGS
                  </h3>
                  <div className="flex flex-wrap gap-2">
                    {selectedTool.tags.map((tag, idx) => (
                      <span
                        key={idx}
                        className="px-3 py-1 bg-[#0d0d0d] text-[#FF8C00] border border-[#FF8C00]/30"
                        style={{ fontFamily: 'Courier New, monospace' }}
                      >
                        {tag.toUpperCase()}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Repository */}
              {selectedTool.repository && (
                <div>
                  <h3 className="text-lg font-bold text-white mb-2" style={{ fontFamily: 'Courier New, monospace' }}>
                    REPOSITORY
                  </h3>
                  <a
                    href={selectedTool.repository}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-[#FF8C00] hover:text-white transition inline-block"
                    style={{ fontFamily: 'Courier New, monospace' }}
                  >
                    {selectedTool.repository} →
                  </a>
                </div>
              )}

              {/* Stats */}
              <div className="grid grid-cols-2 gap-4">
                {selectedTool.downloads !== undefined && (
                  <div className="bg-black border border-[#FF8C00]/30 p-4">
                    <div className="text-[#B0B0B0] text-sm mb-1" style={{ fontFamily: 'Courier New, monospace' }}>
                      DOWNLOADS
                    </div>
                    <div className="text-[#FF8C00] text-2xl font-bold" style={{ fontFamily: 'Courier New, monospace' }}>
                      {selectedTool.downloads}
                    </div>
                  </div>
                )}
                {selectedTool.lastUpdated && (
                  <div className="bg-black border border-[#FF8C00]/30 p-4">
                    <div className="text-[#B0B0B0] text-sm mb-1" style={{ fontFamily: 'Courier New, monospace' }}>
                      LAST UPDATED
                    </div>
                    <div className="text-[#FF8C00] text-lg font-bold" style={{ fontFamily: 'Courier New, monospace' }}>
                      {new Date(selectedTool.lastUpdated).toLocaleDateString().toUpperCase()}
                    </div>
                  </div>
                )}
              </div>

              {/* Install Instructions */}
              <div className="bg-black border border-[#FF8C00]/30 p-4">
                <h3 className="text-lg font-bold text-[#FF8C00] mb-2" style={{ fontFamily: 'Courier New, monospace' }}>
                  ⚡ INSTALL WITH NEX
                </h3>
                <p className="text-[#B0B0B0] text-sm mb-2" style={{ fontFamily: 'Courier New, monospace' }}>
                  RUN THIS COMMAND IN YOUR TERMINAL:
                </p>
                <pre className="bg-[#0d0d0d] border border-[#FF8C00]/50 p-3 text-[#FF8C00] text-sm overflow-x-auto" style={{ fontFamily: 'Courier New, monospace' }}>
                  nex install {selectedTool.id}
                </pre>
                <p className="text-[#B0B0B0] text-sm mt-3" style={{ fontFamily: 'Courier New, monospace' }}>
                  THEN RUN:
                </p>
                <pre className="bg-[#0d0d0d] border border-[#FF8C00]/50 p-3 text-[#FF8C00] text-sm overflow-x-auto" style={{ fontFamily: 'Courier New, monospace' }}>
                  nex run {selectedTool.name.toLowerCase()} --help
                </pre>
              </div>

              {/* Close Button */}
              <button
                onClick={() => setSelectedTool(null)}
                className="w-full px-6 py-3 bg-[#FF8C00] hover:bg-black text-black hover:text-[#FF8C00] border border-[#FF8C00] transition font-medium"
                style={{ fontFamily: 'Courier New, monospace' }}
              >
                CLOSE
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
