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

cd "/workspaces"

echo "Cloning Dependency repositories"

git clone git@bitbucket.org:getinsured/gi-address-validator.git
git clone git@bitbucket.org:getinsured/ms-content.git
git clone -b JDK17_MASTER git@bitbucket.org:getinsured/ghix-lib.git
git clone git@bitbucket.org:getinsured/planmgmt.git
git clone git@bitbucket.org:getinsured/platform.git
git clone git@bitbucket.org:getinsured/models.git
git clone git@bitbucket.org:getinsured/iex.git

echo "Initialize git lfs "
git lfs install

cd "/workspaces/ghix-lib"
echo "Fetching ghix-lib (git lfs)"
git lfs fetch
git lfs checkout

###############################################################################
#  🛠️ BUILDING & CACHING DEPENDENCIES                                         #
###############################################################################
echo "Building base dependencies"
cd "/workspaces/gi-address-validator"
echo "Building base gi-address-validator"
su - dev -c "mvn dependency:resolve"
su - dev -c "mvn clean install -Dmaven.test.skip=true"

# cd "/workspaces/ms-content"
# echo "Building ms-content"
# mvn -q dependency:resolve
# mvn clean install -Dmaven.test.skip=true

###############################################################################
#  🛠️ BUILD PLATFORM                                                         #
###############################################################################
cd "/workspaces/platform"
echo "Building platform"
su - dev -c "mvn dependency:resolve"
su - dev -c "mvn clean install -Dmaven.test.skip=true"

###############################################################################
#  🛠️ BUILD MODELS                                                           #
###############################################################################
cd "/workspaces/models"
echo "Building models"
su - dev -c "mvn dependency:resolve"
su - dev -c "mvn clean install -Dmaven.test.skip=true"

###############################################################################
#  🛠️ BUILD IEX                                                               #
###############################################################################
hix_profile_opts = "-Pnv"

cd "/workspaces/iex"
echo "Building IEX"
su - dev -c "mvn dependency:resolve"
su - dev -c "mvn -q clean install $hix_profile_opts -Dmaven.test.skip=true"

echo "✅ [post-setup] Completed build-time provisioning!"
