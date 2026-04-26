#!/bin/bash
set -euo pipefail

# Deploy AquaSentinel Flutter Web to Vercel
# Usage: ./scripts/deploy-fe.sh [vercel-args]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
APP_DIR="${PROJECT_ROOT}/apps/aqua_sentinel"

echo "🚀 Building AquaSentinel Flutter Web..."
cd "${APP_DIR}"

# Ensure dependencies are up to date
flutter pub get

# Build for production (no base-href needed for Vercel root hosting)
flutter build web --release

echo "📤 Deploying to Vercel..."
cd "${APP_DIR}/build/web"
vercel --prod "$@"

echo "✅ Frontend deployed!"
