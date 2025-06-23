#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  🏗️  BUILD-TIME POST-SETUP SCRIPT                                   ║
# ║      Executes once during `docker build` to perform tasks that       ║
# ║      should be baked into the image.                                ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -euo pipefail

echo "🔧 [post-setup] Installing global npm tools…"
npm install -g yarn eslint

#echo "🔧 [post-setup] Installing Python tooling…"
#pip3 install --no-cache-dir --upgrade pip wheel

cd "/workspace"

echo "Cloning Dependency repositories"
git clone git@bitbucket.org:getinsured/gi-address-validator.git
git clone git@bitbucket.org:getinsured/ms-content.git
git clone -b JDK17 git@bitbucket.org:getinsured/ghix-lib.git
git clone git@bitbucket.org:getinsured/planmgmt.git
git clone git@bitbucket.org:getinsured/platform.git
git clone git@bitbucket.org:getinsured/models.git
git clone git@bitbucket.org:getinsured/iex.git

echo "Initialize git lfs "
git lfs install

cd "/workspace/ghix-lib"
echo "Fetching ghix-lib (git lfs)"  
git lfs fetch
git lfs checkout

echo "Building base dependencies" 
cd "/workspace/gi-address-validator"
mvn -q dependency:resolve
mvn -q clean install -Dmaven.test.skip=true
#cd "/workspaces/ghix-lib/IEX-HOME/lib"

echo "✅ [post-setup] Completed build-time provisioning!"
