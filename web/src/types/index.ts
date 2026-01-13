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
  bootloader: {
    url: string;
    name: string;
    size: number;
  } | null;
  partition: {
    url: string;
    name: string;
    size: number;
  } | null;
  firmware: {
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
      bootloader: string;
      partition: string;
      firmware: string;
    };
  };
  flash: {
    baudrate: number;
    flashOptions: {
      bootloader: {
        address: string;
      };
      partition: {
        address: string;
      };
      firmware: {
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
