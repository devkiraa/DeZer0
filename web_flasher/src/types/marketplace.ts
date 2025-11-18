export interface ToolPackage {
  id: string;
  name: string;
  version: string;
  author: string;
  description: string;
  category: string;
  scriptFilename: string;
  icon?: string;
  tags?: string[];
  downloads?: number;
  lastUpdated?: string;
  repository?: string;
}

export interface ToolManifest {
  tools: ToolPackage[];
}
