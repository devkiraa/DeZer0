import { ToolPackage } from '@/types/marketplace';

export class MarketplaceService {
  private repoOwner = 'devkiraa';
  private repoName = 'DeZer0-Tools';
  private repoContentsUrl = `https://api.github.com/repos/${this.repoOwner}/${this.repoName}/contents/`;
  private rawFileUrlBase = `https://raw.githubusercontent.com/${this.repoOwner}/${this.repoName}/main/`;

  async fetchTools(): Promise<ToolPackage[]> {
    try {
      const response = await fetch(this.repoContentsUrl);
      
      if (!response.ok) {
        throw new Error(`Failed to load tool repository: ${response.statusText}`);
      }

      const contents = await response.json();
      const tools: ToolPackage[] = [];

      for (const item of contents) {
        if (item.type === 'dir') {
          try {
            const manifestUrl = `${this.rawFileUrlBase}${item.name}/manifest.json`;
            const manifestResponse = await fetch(manifestUrl);
            
            if (manifestResponse.ok) {
              const manifestData = await manifestResponse.json();
              tools.push({
                ...manifestData,
                id: item.name,
              });
            }
          } catch (e) {
            console.warn(`Failed to load manifest for ${item.name}:`, e);
          }
        }
      }

      return tools;
    } catch (error) {
      console.error('Failed to fetch tools:', error);
      throw error;
    }
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
