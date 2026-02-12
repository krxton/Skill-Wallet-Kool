/** @type {import('next').NextConfig} */
const nextConfig = {
  // Standalone output for Docker deployment
  output: 'standalone',

  // Suppress workspace root warning
  outputFileTracingRoot: require('path').join(__dirname),

  // Production optimization
  experimental: {
    // Optimize for production builds
    optimizePackageImports: ['lucide-react'],
  },
}

module.exports = nextConfig
