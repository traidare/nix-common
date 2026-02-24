#!/usr/bin/env bash
# Run nix evaluation tests for the nix-common library.
# Usage: bash tests/run-tests.sh  (from repo root)

set -euo pipefail

cd "$(dirname "$0")/.."

echo "Running recursiveDirToModules evaluation tests..."
result=$(nix eval --file tests/recursive-dir-test.nix)
echo "$result"
