import { ToolPackage } from '@/types/marketplace';

interface BlobCacheData {
  tools: ToolPackage[];
  lastUpdated: string;
  totalCount: number;
}

export class MarketplaceService {
  private repoOwner = 'devkiraa';
  private repoName = 'DeZer0-Tools';
  private repoContentsUrl = `https://api.github.com/repos/${this.repoOwner}/${this.repoName}/contents/`;
  private rawFileUrlBase = `https://raw.githubusercontent.com/${this.repoOwner}/${this.repoName}/main/`;
  private toolDirectories: string[] | null = null;
  private cachedTools: ToolPackage[] | null = null;

  async fetchFromBlobCache(): Promise<BlobCacheData | null> {
    try {
      // Fetch the blob cache URL from our API endpoint
      const response = await fetch('/api/tools/cache', {
        next: { revalidate: 3600 } // Cache for 1 hour
      });
      
      if (!response.ok) {
        console.warn('Blob cache not available, falling back to GitHub');
        return null;
      }

      const data: BlobCacheData = await response.json();
      console.log(`Loaded ${data.totalCount} tools from blob cache (updated: ${data.lastUpdated})`);
      return data;
    } catch (error) {
      console.warn('Failed to fetch from blob cache:', error);
      return null;
    }
  }

  async getToolDirectories(): Promise<string[]> {
    if (this.toolDirectories !== null) {
      return this.toolDirectories;
    }

    try {
      const response = await fetch(this.repoContentsUrl);
      
      if (!response.ok) {
        throw new Error(`Failed to load tool repository: ${response.statusText}`);
      }

      const contents = await response.json();
      const directories = contents
        .filter((item: any) => item.type === 'dir')
        .map((item: any) => item.name);
      
      this.toolDirectories = directories;
      return directories;
    } catch (error) {
      console.error('Failed to fetch tool directories:', error);
      throw error;
    }
  }

  async fetchTools(limit?: number, offset: number = 0): Promise<ToolPackage[]> {
    try {
      // Try to fetch from blob cache first
      const blobData = await this.fetchFromBlobCache();
      
      if (blobData && blobData.tools.length > 0) {
        this.cachedTools = blobData.tools;
        
        // Return paginated results from cache
        if (limit) {
          return blobData.tools.slice(offset, offset + limit);
        }
        return blobData.tools;
      }

      // Fallback to GitHub API if blob cache is unavailable
      console.log('Fetching from GitHub API...');
      const directories = await this.getToolDirectories();
      const toolsToFetch = limit 
        ? directories.slice(offset, offset + limit)
        : directories;
      
      const tools: ToolPackage[] = [];

      for (const dirName of toolsToFetch) {
        try {
          const manifestUrl = `${this.rawFileUrlBase}${dirName}/manifest.json`;
          const manifestResponse = await fetch(manifestUrl);
          
          if (manifestResponse.ok) {
            const manifestData = await manifestResponse.json();
            tools.push({
              ...manifestData,
              id: dirName,
            });
          }
        } catch (e) {
          console.warn(`Failed to load manifest for ${dirName}:`, e);
        }
      }

      return tools;
    } catch (error) {
      console.error('Failed to fetch tools:', error);
      throw error;
    }
  }

  async getTotalToolCount(): Promise<number> {
    // If we have cached tools, return that count
    if (this.cachedTools) {
      return this.cachedTools.length;
    }

    // Try blob cache first
    const blobData = await this.fetchFromBlobCache();
    if (blobData) {
      return blobData.totalCount;
    }

    // Fallback to GitHub
    const directories = await this.getToolDirectories();
    return directories.length;
  }

  async downloadTool(
    packageId: string,
    scriptFilename: string,
    onProgress?: (progress: number) => void
  ): Promise<Uint8Array> {
    const downloadUrl = `${this.rawFileUrlBase}${packageId}/${scriptFilename}`;

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

  getCategoryIcon(category: string): string {
    const icons: Record<string, string> = {
      'WiFi': '📡',
      'Bluetooth': '📱',
      'Security': '🔒',
      'Network': '🌐',
      'Hardware': '⚙️',
      'Utility': '🛠️',
      'IoT': '🏠',
      'Development': '💻',
      'Testing': '🧪',
    };
    return icons[category] || '📦';
  }
}

export const marketplaceService = new MarketplaceService();
