import { put, del, list } from '@vercel/blob';
import { NextResponse } from 'next/server';

interface ToolPackage {
  id: string;
  name: string;
  description: string;
  version: string;
  author: string;
  category: string;
  icon?: string;
  requires_wifi?: boolean;
  requires_ble?: boolean;
  esp_code_url?: string;
  app_code_url?: string;
  web_flasher_url?: string;
  readme_url?: string;
  created_at?: string;
  updated_at?: string;
}

async function fetchAllToolsFromGitHub(): Promise<ToolPackage[]> {
  const owner = 'devkiraa';
  const repo = 'DeZer0-Tools';
  const repoUrl = `https://api.github.com/repos/${owner}/${repo}/contents`;

  try {
    // Fetch repository contents
    const response = await fetch(repoUrl, {
      headers: {
        'Accept': 'application/vnd.github.v3+json',
      },
      next: { revalidate: 0 } // Don't cache this request
    });

    if (!response.ok) {
      throw new Error(`GitHub API error: ${response.status}`);
    }

    const contents = await response.json();
    const directories = contents
      .filter((item: any) => item.type === 'dir')
      .map((item: any) => item.name);
    
    console.log(`Found ${directories.length} tool directories:`, directories);

    // Fetch all manifests in parallel
    const manifestPromises = directories.map(async (dir: string) => {
      try {
        const manifestUrl = `https://raw.githubusercontent.com/${owner}/${repo}/main/${dir}/manifest.json`;
        const manifestResponse = await fetch(manifestUrl, {
          next: { revalidate: 0 }
        });
        
        if (!manifestResponse.ok) {
          console.warn(`Failed to fetch manifest for ${dir}`);
          return null;
        }

        const manifest = await manifestResponse.json();
        return {
          ...manifest,
          id: dir,
        };
      } catch (error) {
        console.warn(`Error fetching manifest for ${dir}:`, error);
        return null;
      }
    });

    const tools = (await Promise.all(manifestPromises)).filter(
      (tool): tool is ToolPackage => tool !== null
    );

    return tools;
  } catch (error) {
    console.error('Error fetching tools from GitHub:', error);
    throw error;
  }
}

export async function GET() {
  try {
    console.log('Starting tools sync to Vercel Blob...');
    
    // Fetch all tools from GitHub
    const tools = await fetchAllToolsFromGitHub();
    
    // Delete existing cache if it exists
    try {
      const { blobs } = await list({ limit: 10 });
      const existingBlob = blobs.find(b => b.pathname === 'tools-cache.json');
      if (existingBlob) {
        await del(existingBlob.url);
        console.log('Deleted existing cache');
      }
    } catch (error) {
      console.log('No existing cache to delete');
    }
    
    // Store in Vercel Blob
    const blob = await put('tools-cache.json', JSON.stringify({
      tools,
      lastUpdated: new Date().toISOString(),
      totalCount: tools.length,
    }), {
      access: 'public',
      contentType: 'application/json',
    });

    console.log(`Successfully synced ${tools.length} tools to Vercel Blob`);

    return NextResponse.json({
      success: true,
      message: `Synced ${tools.length} tools`,
      url: blob.url,
      lastUpdated: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Error syncing tools:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      { status: 500 }
    );
  }
}
