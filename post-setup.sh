#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  🏗️  BUILD-TIME POST-SETUP SCRIPT                                   ║
# ║      Executes once during `docker build` to perform tasks that       ║
# ║      should be baked into the image.                                ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -euo pipefail

echo "🔧 [post-setup] Installing global npm tools…"
npm install -g yarn @eslint/cli

echo "🔧 [post-setup] Creating developer tools directory…"
mkdir -p /opt/devtools

echo "🔧 [post-setup] Installing Python tooling…"
pip3 install --no-cache-dir --upgrade pip wheel

echo "✅ [post-setup] Completed build-time provisioning!"
