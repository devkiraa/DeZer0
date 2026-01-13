import { ToolPackage, NexPackage, convertNexToToolPackage } from '@/types/marketplace';

interface BlobCacheData {
  tools: ToolPackage[];
  lastUpdated: string;
  totalCount: number;
}

/**
 * MarketplaceService - Fetches tools from Nex Registry API
 * 
 * Nex is a universal package manager for developer tools.
 * Base API URL: https://nex-9ujp.onrender.com/api
 * 
 * The service fetches packages from the Nex central registry and converts them
 * to the ToolPackage format expected by the DeZer0 app.
 */
export class MarketplaceService {
  // Nex Registry API configuration
  private nexApiBase = 'https://nex-9ujp.onrender.com/api';

  // Local cache
  private cachedTools: ToolPackage[] | null = null;
  private totalToolCount: number | null = null;

  /**
   * Fetch tools from Vercel Blob cache (faster, pre-synced)
   */
  async fetchFromBlobCache(): Promise<BlobCacheData | null> {
    try {
      const response = await fetch('/api/tools/cache', {
        next: { revalidate: 3600 } // Cache for 1 hour
      });

      if (!response.ok) {
        console.warn('Blob cache not available, falling back to Nex API');
        return null;
      }

      const data: BlobCacheData = await response.json();
      console.log(`✅ Loaded ${data.totalCount} tools from blob cache (updated: ${data.lastUpdated})`);
      return data;
    } catch (error) {
      console.warn('Failed to fetch from blob cache:', error);
      return null;
    }
  }

  /**
   * Fetch packages directly from Nex Registry API
   * Endpoint: GET /packages
   */
  async fetchFromNexApi(limit?: number, offset: number = 0): Promise<{ tools: ToolPackage[]; total: number }> {
    try {
      // Build query params
      const params = new URLSearchParams();
      if (limit) params.set('limit', limit.toString());
      if (offset > 0) params.set('offset', offset.toString());

      const url = `${this.nexApiBase}/packages${params.toString() ? '?' + params.toString() : ''}`;
      console.log(`🔄 Fetching from Nex API: ${url}`);

      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
        },
        next: { revalidate: 0 } // Don't cache API requests
      });

      if (!response.ok) {
        throw new Error(`Nex API error: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();

      // Handle both direct array and wrapped response formats
      let packages: NexPackage[] = [];
      let total: number = 0;

      if (Array.isArray(data)) {
        packages = data;
        total = data.length;
      } else if (data.data && Array.isArray(data.data)) {
        packages = data.data;
        total = data.total || data.data.length;
      } else if (data.packages && Array.isArray(data.packages)) {
        packages = data.packages;
        total = data.total || data.packages.length;
      }

      // Convert Nex packages to ToolPackage format
      const tools = packages.map(convertNexToToolPackage);

      console.log(`✅ Fetched ${tools.length} tools from Nex API (total: ${total})`);
      return { tools, total };
    } catch (error) {
      console.error('Failed to fetch from Nex API:', error);
      throw error;
    }
  }

  /**
   * Search packages in Nex Registry
   * Endpoint: GET /packages?search=query
   */
  async searchPackages(query: string): Promise<ToolPackage[]> {
    try {
      const url = `${this.nexApiBase}/packages?search=${encodeURIComponent(query)}`;

      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`Nex API search error: ${response.status}`);
      }

      const data = await response.json();
      const packages: NexPackage[] = Array.isArray(data) ? data : (data.data || data.packages || []);

      return packages.map(convertNexToToolPackage);
    } catch (error) {
      console.error('Failed to search Nex packages:', error);
      throw error;
    }
  }

  /**
   * Get a specific package by ID
   * Endpoint: GET /packages/:id
   */
  async getPackageById(packageId: string): Promise<ToolPackage | null> {
    try {
      const url = `${this.nexApiBase}/packages/${encodeURIComponent(packageId)}`;

      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
        },
      });

      if (!response.ok) {
        if (response.status === 404) return null;
        throw new Error(`Nex API error: ${response.status}`);
      }

      const data = await response.json();
      const pkg: NexPackage = data.data || data;

      return convertNexToToolPackage(pkg);
    } catch (error) {
      console.error(`Failed to fetch package ${packageId}:`, error);
      return null;
    }
  }

  /**
   * Main method to fetch tools (tries blob cache first, falls back to Nex API)
   */
  async fetchTools(limit?: number, offset: number = 0): Promise<ToolPackage[]> {
    try {
      // Try to fetch from blob cache first
      const blobData = await this.fetchFromBlobCache();

      if (blobData && blobData.tools.length > 0) {
        this.cachedTools = blobData.tools;
        this.totalToolCount = blobData.totalCount;

        // Return paginated results from cache
        if (limit) {
          return blobData.tools.slice(offset, offset + limit);
        }
        return blobData.tools;
      }

      // Fallback to Nex API if blob cache is unavailable
      console.log('📡 Falling back to Nex API...');
      const { tools, total } = await this.fetchFromNexApi(limit, offset);

      this.cachedTools = tools;
      this.totalToolCount = total;

      return tools;
    } catch (error) {
      console.error('Failed to fetch tools:', error);
      throw error;
    }
  }

  /**
   * Get total count of available tools
   */
  async getTotalToolCount(): Promise<number> {
    if (this.totalToolCount !== null) {
      return this.totalToolCount;
    }

    // Try blob cache first
    const blobData = await this.fetchFromBlobCache();
    if (blobData) {
      this.totalToolCount = blobData.totalCount;
      return blobData.totalCount;
    }

    // Fallback to Nex API
    const { total } = await this.fetchFromNexApi(1, 0);
    this.totalToolCount = total;
    return total;
  }

  /**
   * Download a tool's source code from its repository
   */
  async downloadTool(
    packageId: string,
    scriptFilename: string,
    onProgress?: (progress: number) => void
  ): Promise<Uint8Array> {
    // First, get the package to find its repository
    const pkg = await this.getPackageById(packageId);

    if (!pkg || !pkg.repository) {
      throw new Error(`Package ${packageId} not found or has no repository`);
    }

    // Extract GitHub raw URL from repository
    // Convert https://github.com/user/repo to https://raw.githubusercontent.com/user/repo/main/
    const repoUrl = pkg.repository
      .replace('github.com', 'raw.githubusercontent.com')
      .replace(/\/$/, '');

    const downloadUrl = `${repoUrl}/main/${scriptFilename}`;
    console.log(`📥 Downloading from: ${downloadUrl}`);

    const response = await fetch(downloadUrl);

    if (!response.ok) {
      throw new Error(`Failed to download tool: ${response.statusText}`);
    }

    const contentLength = response.headers.get('content-length');
    const total = contentLength ? parseInt(contentLength, 10) : 0;

    if (!response.body || !total || !onProgress) {
      const buffer = await response.arrayBuffer();
      return new Uint8Array(buffer);
    }

    const reader = response.body.getReader();
    const chunks: Uint8Array[] = [];
    let receivedLength = 0;

    while (true) {
      const { done, value } = await reader.read();

      if (done) break;

      chunks.push(value);
      receivedLength += value.length;

      if (onProgress) {
        onProgress((receivedLength / total) * 100);
      }
    }

    const chunksAll = new Uint8Array(receivedLength);
    let position = 0;
    for (const chunk of chunks) {
      chunksAll.set(chunk, position);
      position += chunk.length;
    }

    return chunksAll;
  }

  /**
   * Get category icon for display (maps Nex categories to icons)
   */
  getCategoryIcon(category: string): string {
    const icons: Record<string, string> = {
      // Nex categories
      'CLI': '💻',
      'Utility': '🛠️',
      'Development': '⚙️',
      'Automation': '🤖',
      'Data': '📊',
      'Web': '🌐',
      'Security': '🔒',
      'Other': '📦',
      // ESP32/DeZer0 specific categories
      'WiFi': '📡',
      'Bluetooth': '📱',
      'GPIO': '🔌',
      'Hardware': '🖥️',
      'Network': '🌐',
      'IoT': '🏠',
      'Testing': '🧪',
    };
    return icons[category] || '📦';
  }

  /**
   * Get install command for CLI display
   */
  getInstallCommand(packageId: string): string {
    return `nex install ${packageId}`;
  }

  /**
   * Get run command for CLI display
   */
  getRunCommand(packageName: string): string {
    return `nex run ${packageName}`;
  }
}

export const marketplaceService = new MarketplaceService();
