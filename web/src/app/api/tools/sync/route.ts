import { put, del, list } from '@vercel/blob';
import { NextResponse } from 'next/server';
import { NexPackage, ToolPackage, convertNexToToolPackage } from '@/types/marketplace';

/**
 * Sync Tools from Nex Registry API to Vercel Blob Cache
 * 
 * This endpoint fetches all packages from the Nex Registry API
 * and stores them in Vercel Blob for faster access.
 * 
 * Nex API Base: https://nex-9ujp.onrender.com/api
 * Endpoint: GET /packages
 */

const NEX_API_BASE = 'https://nex-9ujp.onrender.com/api';

async function fetchAllToolsFromNexApi(): Promise<ToolPackage[]> {
  try {
    console.log('🔄 Fetching packages from Nex Registry API...');

    // Fetch all packages from Nex API
    const response = await fetch(`${NEX_API_BASE}/packages`, {
      headers: {
        'Accept': 'application/json',
      },
      next: { revalidate: 0 } // Don't cache this request
    });

    if (!response.ok) {
      throw new Error(`Nex API error: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();

    // Handle both direct array and wrapped response formats
    let packages: NexPackage[] = [];

    if (Array.isArray(data)) {
      packages = data;
    } else if (data.data && Array.isArray(data.data)) {
      packages = data.data;
    } else if (data.packages && Array.isArray(data.packages)) {
      packages = data.packages;
    }

    console.log(`📦 Found ${packages.length} packages in Nex Registry`);

    // Convert Nex packages to ToolPackage format
    const tools = packages.map(convertNexToToolPackage);

    return tools;
  } catch (error) {
    console.error('❌ Error fetching from Nex API:', error);
    throw error;
  }
}

export async function GET() {
  try {
    console.log('🚀 Starting tools sync from Nex Registry to Vercel Blob...');

    // Fetch all tools from Nex API
    const tools = await fetchAllToolsFromNexApi();

    if (tools.length === 0) {
      return NextResponse.json({
        success: false,
        message: 'No tools found in Nex Registry',
      }, { status: 404 });
    }

    // Delete existing cache if it exists
    try {
      const { blobs } = await list({ limit: 10 });
      const existingBlob = blobs.find(b => b.pathname === 'tools-cache.json');
      if (existingBlob) {
        await del(existingBlob.url);
        console.log('🗑️ Deleted existing cache');
      }
    } catch (error) {
      console.log('ℹ️ No existing cache to delete');
    }

    // Store in Vercel Blob
    const cacheData = {
      tools,
      lastUpdated: new Date().toISOString(),
      totalCount: tools.length,
      source: 'nex-registry',
      apiVersion: 'v1',
    };

    const blob = await put('tools-cache.json', JSON.stringify(cacheData), {
      access: 'public',
      contentType: 'application/json',
    });

    console.log(`✅ Successfully synced ${tools.length} tools to Vercel Blob`);

    return NextResponse.json({
      success: true,
      message: `Synced ${tools.length} tools from Nex Registry`,
      url: blob.url,
      lastUpdated: cacheData.lastUpdated,
      totalCount: tools.length,
      source: 'nex-registry',
    });
  } catch (error) {
    console.error('❌ Error syncing tools:', error);
    return NextResponse.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        source: 'nex-registry',
      },
      { status: 500 }
    );
  }
}

// POST method to force sync
export async function POST() {
  return GET();
}
