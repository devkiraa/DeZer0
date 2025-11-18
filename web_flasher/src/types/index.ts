export interface GitHubRelease {
  id: number;
  tag_name: string;
  name: string;
  body: string;
  published_at: string;
  assets: GitHubAsset[];
}

export interface GitHubAsset {
  name: string;
  browser_download_url: string;
  size: number;
  download_count: number;
}

export interface FirmwareFiles {
  firmware: {
    url: string;
    name: string;
    size: number;
  } | null;
  filesystem: {
    url: string;
    name: string;
    size: number;
  } | null;
}

export interface Config {
  github: {
    owner: string;
    repo: string;
    firmwareAssetPatterns: {
      firmware: string;
      filesystem: string;
    };
  };
  flash: {
    baudrate: number;
    flashOptions: {
      firmware: {
        address: string;
      };
      filesystem: {
        address: string;
      };
      flashSize: string;
      flashFreq: string;
      flashMode: string;
      eraseAll: boolean;
    };
  };
}

export interface FlashProgress {
  percentage: number;
  message: string;
}
