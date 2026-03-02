/** @type {import('next').NextConfig} */

// ---------------------------------------------------------------------------
// CDN / Asset Prefix Configuration  (core piece under test)
// ---------------------------------------------------------------------------
const cdnBase = process.env.NEXT_PUBLIC_CDN_BASE_URL
const env = process.env.VERCEL_ENV                     // 'production' | 'preview'
const app = process.env.NEXT_PUBLIC_APP_NAME           // e.g. 'td-cdn-demo'
const version = process.env.VERCEL_DEPLOYMENT_ID       // e.g. 'dpl_abc123'

const assetPrefix = cdnBase && env && app && version
  ? `${cdnBase}/app/${env}/${app}/v/${version}`
  : undefined

const nextConfig = {
  reactStrictMode: true,
  ...(assetPrefix ? { assetPrefix } : {}),

  env: {
    API_ENV: process.env.API_ENV || 'test'
  },

  images: {
    unoptimized: true
  }
}

module.exports = nextConfig
