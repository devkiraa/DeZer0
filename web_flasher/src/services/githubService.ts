import { GitHubRelease, FirmwareFiles, Config } from '@/types';

export class GitHubService {
  private config: Config | null = null;

  async loadConfig(): Promise<Config> {
    if (this.config) return this.config;
    
    const response = await fetch('/data/config.json');
    if (!response.ok) {
      throw new Error('Failed to load configuration');
    }
    this.config = await response.json();
    return this.config!;
  }

  async getLatestRelease(): Promise<GitHubRelease> {
    const config = await this.loadConfig();
    const { owner, repo } = config.github;
    
    const response = await fetch(
      `https://api.github.com/repos/${owner}/${repo}/releases/latest`,
      {
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      }
    );

    if (!response.ok) {
      throw new Error(`Failed to fetch latest release: ${response.statusText}`);
    }

    return response.json();
  }

  async getAllReleases(): Promise<GitHubRelease[]> {
    const config = await this.loadConfig();
    const { owner, repo } = config.github;
    
    const response = await fetch(
      `https://api.github.com/repos/${owner}/${repo}/releases`,
      {
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      }
    );

    if (!response.ok) {
      throw new Error(`Failed to fetch releases: ${response.statusText}`);
    }

    return response.json();
  }

  async getFirmwareFiles(release: GitHubRelease): Promise<FirmwareFiles> {
    const config = await this.loadConfig();
    const patterns = config.github.firmwareAssetPatterns;

    const firmwareAsset = release.assets.find(asset => 
      new RegExp(patterns.firmware, 'i').test(asset.name)
    );

    const filesystemAsset = release.assets.find(asset => 
      new RegExp(patterns.filesystem, 'i').test(asset.name)
    );

    return {
      firmware: firmwareAsset ? {
        url: firmwareAsset.browser_download_url,
        name: firmwareAsset.name,
        size: firmwareAsset.size,
      } : null,
      filesystem: filesystemAsset ? {
        url: filesystemAsset.browser_download_url,
        name: filesystemAsset.name,
        size: filesystemAsset.size,
      } : null,
    };
  }

  async downloadFirmwareFile(url: string, onProgress?: (percentage: number) => void): Promise<ArrayBuffer> {
    const response = await fetch(url);
    
    if (!response.ok) {
      throw new Error(`Failed to download file: ${response.statusText}`);
    }

    const contentLength = response.headers.get('content-length');
    const total = contentLength ? parseInt(contentLength, 10) : 0;

    if (!response.body || !total || !onProgress) {
      return response.arrayBuffer();
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
        onProgress(Math.round((receivedLength / total) * 100));
      }
    }

    const chunksAll = new Uint8Array(receivedLength);
    let position = 0;
    for (const chunk of chunks) {
      chunksAll.set(chunk, position);
      position += chunk.length;
    }

    return chunksAll.buffer;
  }

  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
  }
}

export const githubService = new GitHubService();
