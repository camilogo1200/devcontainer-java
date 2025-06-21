#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  🚀  RUNTIME ENTRYPOINT WRAPPER                                     ║
# ║      This script runs each time the container starts. After doing   ║
# ║      its work it execs the CMD given by Docker (default: bash).     ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -euo pipefail

echo "🌟 Container booting…"
echo "   Java  : $(java -version 2>&1 | head -n1)"
echo "   Node  : $(node -v)"
echo "   Maven : $(mvn -v | head -n1)"
echo "   Yarn  : $(yarn -v)"

# Example runtime initialization (safe for idempotent runs)
if [ ! -d "$HOME/.cache/yarn" ]; then
  echo "🔧 First-run setup: priming Yarn cache directory…"
  mkdir -p "$HOME/.cache/yarn"
fi

echo "🚀 Handing off to container CMD: $*"
exec "$@"
