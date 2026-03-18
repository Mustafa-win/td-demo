#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# upload-static-to-r2.sh
#
# Uploads the Next.js static build output (.next/static) to Cloudflare R2
# under a deployment-versioned path so that old assets remain available
# even after a new Vercel deploy — eliminating stale-cache 404s.
#
# Usage:
#   NEXT_PUBLIC_APP_VERSION=0.1.1 VERCEL_ENV=production NEXT_PUBLIC_APP_NAME=trustdice-web \
#     R2_BUCKET=my-bucket R2_ACCOUNT_ID=abc123 STATIC_DIR=.next/static \
#     ./scripts/upload-static-to-r2.sh
#
# Required environment variables:
#   NEXT_PUBLIC_APP_VERSION            — version from package.json (set by CI)
#   VERCEL_ENV             — deployment environment ('production' | 'preview')
#   NEXT_PUBLIC_APP_NAME   — application name (e.g. 'trustdice-web')
#   R2_BUCKET              — name of the Cloudflare R2 bucket
#   R2_ACCOUNT_ID          — Cloudflare account ID
#   STATIC_DIR             — path to the static assets directory
# ---------------------------------------------------------------------------

set -euo pipefail

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
STATIC_DIR="${STATIC_DIR:?'STATIC_DIR is required'}"
DEPLOY_ID="${NEXT_PUBLIC_APP_VERSION:?'NEXT_PUBLIC_APP_VERSION is required'}"
DEPLOY_ENV="${VERCEL_ENV:?'VERCEL_ENV is required'}"
APP_NAME="${NEXT_PUBLIC_APP_NAME:?'NEXT_PUBLIC_APP_NAME is required'}"
BUCKET="${R2_BUCKET:?'R2_BUCKET is required'}"
# Wrangler v4 reads account ID from CLOUDFLARE_ACCOUNT_ID env var
export CLOUDFLARE_ACCOUNT_ID="${R2_ACCOUNT_ID:?'R2_ACCOUNT_ID is required'}"
DEST_PREFIX="app/${DEPLOY_ENV}/${APP_NAME}/v/${DEPLOY_ID}/_next/static"

# ---------------------------------------------------------------------------
# Validate
# ---------------------------------------------------------------------------
if [ ! -d "$STATIC_DIR" ]; then
  echo "❌ Static directory not found: ${STATIC_DIR}"
  echo "   Run 'next build' first."
  exit 1
fi

# Resolve wrangler: prefer global, fall back to npx
if command -v wrangler &> /dev/null; then
  WRANGLER="wrangler"
else
  WRANGLER="npx wrangler"
fi

# ---------------------------------------------------------------------------
# Upload
# ---------------------------------------------------------------------------
echo "📦 Uploading static assets to R2..."
echo "   Source:      ${STATIC_DIR}"
echo "   Destination: r2://${BUCKET}/${DEST_PREFIX}"
echo ""

FILE_COUNT=0

find "$STATIC_DIR" -type f | while read -r FILE; do
  # Build the R2 object key by replacing the local prefix with the remote prefix
  RELATIVE_PATH="${FILE#$STATIC_DIR/}"
  OBJECT_KEY="${DEST_PREFIX}/${RELATIVE_PATH}"

  # TODO: entire /_next/static
  # Determine content-type based on extension
  CONTENT_TYPE="application/octet-stream"
  case "$FILE" in
    *.js)    CONTENT_TYPE="application/javascript" ;;
    *.css)   CONTENT_TYPE="text/css" ;;
    *.json)  CONTENT_TYPE="application/json" ;;
    *.map)   CONTENT_TYPE="application/json" ;;
    *.svg)   CONTENT_TYPE="image/svg+xml" ;;
    *.png)   CONTENT_TYPE="image/png" ;;
    *.jpg|*.jpeg) CONTENT_TYPE="image/jpeg" ;;
    *.webp)  CONTENT_TYPE="image/webp" ;;
    *.avif)  CONTENT_TYPE="image/avif" ;;
    *.woff)  CONTENT_TYPE="font/woff" ;;
    *.woff2) CONTENT_TYPE="font/woff2" ;;
    *.txt)   CONTENT_TYPE="text/plain" ;;
    *.html)  CONTENT_TYPE="text/html" ;;
  esac

  $WRANGLER r2 object put "${BUCKET}/${OBJECT_KEY}" \
    --file "$FILE" \
    --content-type "$CONTENT_TYPE" \
    --cache-control "public, max-age=31536000, immutable" \
    --remote

  FILE_COUNT=$((FILE_COUNT + 1))
done

echo ""
echo "✅ Upload complete. Assets available at: /${DEST_PREFIX}/"
