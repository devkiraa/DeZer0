# Tools Cache Setup

This setup uses Vercel Blob Storage to cache all tools from the GitHub repository, providing faster load times for the marketplace.

## How It Works

1. **Automatic Sync**: A cron job runs every 6 hours to sync all tools from GitHub to Vercel Blob
2. **Fast Loading**: The marketplace loads tools from blob storage (instant) instead of fetching from GitHub API
3. **Fallback**: If blob cache is unavailable, it automatically falls back to GitHub API

## Setup Instructions

### 1. Enable Vercel Blob Storage

1. Go to your Vercel project dashboard
2. Navigate to **Storage** tab
3. Click **Create Database** → **Blob**
4. Create a new blob store (any name, e.g., "dezero-tools-cache")

### 2. Environment Variables

Vercel automatically adds `BLOB_READ_WRITE_TOKEN` when you create a blob store.
No additional configuration needed!

### 3. Initial Sync

After deployment, trigger the initial sync:

**Option 1: Visit the sync URL**
```
https://your-domain.vercel.app/api/tools/sync
```

**Option 2: Use curl**
```bash
curl https://your-domain.vercel.app/api/tools/sync
```

You should see a response like:
```json
{
  "success": true,
  "message": "Synced 15 tools",
  "url": "https://xxx.public.blob.vercel-storage.com/tools-cache.json",
  "lastUpdated": "2025-11-18T..."
}
```

### 4. Verify

1. Visit your marketplace page
2. Open browser DevTools → Network tab
3. Look for `/api/tools/cache` request
4. Verify it loads instantly with cached data

## Cron Schedule

The sync runs automatically every 6 hours:
- 00:00 UTC
- 06:00 UTC
- 12:00 UTC
- 18:00 UTC

To change the schedule, edit `vercel.json`:
```json
{
  "crons": [
    {
      "path": "/api/tools/sync",
      "schedule": "0 */6 * * *"
    }
  ]
}
```

## API Endpoints

### `/api/tools/sync` (GET)
Syncs all tools from GitHub to Vercel Blob.

**Response:**
```json
{
  "success": true,
  "message": "Synced 15 tools",
  "url": "https://...",
  "lastUpdated": "2025-11-18T..."
}
```

### `/api/tools/cache` (GET)
Retrieves cached tools data.

**Response:**
```json
{
  "tools": [...],
  "lastUpdated": "2025-11-18T...",
  "totalCount": 15
}
```

## Benefits

- ⚡ **Instant Loading**: Loads all tools in one fast request
- 🔄 **Auto-Update**: Cron job keeps cache fresh every 6 hours
- 🛡️ **Fallback**: Automatically uses GitHub API if cache fails
- 💰 **No Rate Limits**: Avoids GitHub API rate limiting issues
- 🌐 **CDN Cached**: Blob storage is CDN-cached globally

## Troubleshooting

### Cache not loading?
1. Check if blob store is created in Vercel dashboard
2. Verify `BLOB_READ_WRITE_TOKEN` exists in environment variables
3. Trigger manual sync: visit `/api/tools/sync`

### Stale data?
Manual sync: `curl https://your-domain.vercel.app/api/tools/sync`

### Want more frequent updates?
Change cron schedule in `vercel.json` (minimum: every 1 hour on Pro plan)
