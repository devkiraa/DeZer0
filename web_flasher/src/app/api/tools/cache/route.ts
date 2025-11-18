import { list } from '@vercel/blob';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    // List all blobs and find the tools cache
    const { blobs } = await list({
      limit: 10,
    });

    const toolsCacheBlob = blobs.find(blob => blob.pathname === 'tools-cache.json');

    if (!toolsCacheBlob) {
      return NextResponse.json(
        { error: 'Tools cache not found' },
        { status: 404 }
      );
    }

    // Fetch the blob data
    const response = await fetch(toolsCacheBlob.url);
    const data = await response.json();

    return NextResponse.json(data, {
      headers: {
        'Cache-Control': 'public, s-maxage=3600, stale-while-revalidate=7200',
      },
    });
  } catch (error) {
    console.error('Error fetching tools cache:', error);
    return NextResponse.json(
      { error: 'Failed to fetch tools cache' },
      { status: 500 }
    );
  }
}
