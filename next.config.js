/** @type {import('next').NextConfig} */
const { DefinePlugin } = require('webpack')

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

  images: {
    unoptimized: true
  },

  webpack(config) {
    config.plugins.push(
      new DefinePlugin({
        'process.env.API_ENV': JSON.stringify(process.env.API_ENV || 'test'),
        'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV || 'development')
      })
    )
    return config
  }
}

module.exports = nextConfig
