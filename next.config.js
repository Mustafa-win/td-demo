/** @type {import('next').NextConfig} */

const fs = require('node:fs') // eslint-disable-line @typescript-eslint/no-require-imports

// ---------------------------------------------------------------------------
// CDN / Asset Prefix Configuration  (core piece under test)
// ---------------------------------------------------------------------------
const cdnBase = process.env.NEXT_PUBLIC_CDN_BASE_URL  // pub-9fa145a4807f4bb291212c7d2b0f25bb.r2.dev
const env = process.env.VERCEL_ENV                    // production
const app = process.env.NEXT_PUBLIC_APP_NAME          // td-cdn-demo
const { version } = JSON.parse(fs.readFileSync('./package.json', 'utf8')) // auto-versioned by CI

// https://pub-9fa145a4807f4bb291212c7d2b0f25bb.r2.dev/app/production/td-cdn-demo/v/0.1.1/_next/static/media/vercel.238827ec.svg
const assetPrefix = cdnBase && env && app && version
  ? `${cdnBase}/app/${env}/${app}/v/${version}`
  : undefined

const nextConfig = {
  reactStrictMode: true,
  ...(assetPrefix ? { assetPrefix } : {}),

  env: {
    API_ENV: process.env.API_ENV || 'test',
    NEXT_PUBLIC_APP_VERSION: version,
  },

  images: {
    unoptimized: true
  }
}

module.exports = nextConfig
