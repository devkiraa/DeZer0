// Nex Package Types - Compatible with Nex Registry API
// Base URL: https://nex-9ujp.onrender.com/api

export interface NexAuthor {
  name: string;
  github: string;
}

export interface NexRuntime {
  type: 'python' | 'node' | 'bash' | 'powershell' | 'binary' | 'go';
}

export interface NexCommands {
  default: string;
  install?: string;
}

// Raw Nex package format from API
export interface NexPackage {
  id: string;                    // format: "author.package-name"
  name: string;
  version: string;
  description: string;
  author: NexAuthor;
  license?: string;
  repository: string;
  runtime: NexRuntime;
  entrypoint: string;
  commands: NexCommands;
  keywords?: string[];
  category: 'cli' | 'utility' | 'development' | 'automation' | 'data' | 'web' | 'security' | 'other';
  downloads?: number;
  createdAt?: string;
  updatedAt?: string;
}

// Adapted ToolPackage format for DeZer0 app compatibility
export interface ToolPackage {
  id: string;
  name: string;
  version: string;
  author: string;
  description: string;
  category: string;
  scriptFilename: string;      // Mapped from entrypoint
  icon?: string;
  tags?: string[];             // Mapped from keywords
  downloads?: number;
  lastUpdated?: string;        // Mapped from updatedAt
  repository?: string;
  runtime?: string;            // Runtime type for ESP32 compatibility
  commands?: NexCommands;      // Keep original commands for reference
}

export interface ToolManifest {
  tools: ToolPackage[];
}

// Nex API Response Types
export interface NexApiResponse {
  success: boolean;
  data: NexPackage[];
  total?: number;
  page?: number;
  limit?: number;
}

export interface NexPackageResponse {
  success: boolean;
  data: NexPackage;
}

// Category mapping from Nex to DeZer0 display categories
export const NexCategoryMapping: Record<string, string> = {
  'cli': 'CLI',
  'utility': 'Utility',
  'development': 'Development',
  'automation': 'Automation',
  'data': 'Data',
  'web': 'Web',
  'security': 'Security',
  'other': 'Other',
  // ESP32-specific categories for DeZer0
  'wifi': 'WiFi',
  'bluetooth': 'Bluetooth',
  'gpio': 'GPIO',
  'hardware': 'Hardware',
  'network': 'Network',
  'iot': 'IoT',
};

// Utility function to convert NexPackage to ToolPackage
export function convertNexToToolPackage(nex: NexPackage): ToolPackage {
  return {
    id: nex.id,
    name: nex.name,
    version: nex.version,
    author: nex.author.name || nex.author.github,
    description: nex.description,
    category: NexCategoryMapping[nex.category] || nex.category,
    scriptFilename: nex.entrypoint,
    tags: nex.keywords,
    downloads: nex.downloads,
    lastUpdated: nex.updatedAt,
    repository: nex.repository,
    runtime: nex.runtime?.type,
    commands: nex.commands,
  };
}
