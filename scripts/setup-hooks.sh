#!/usr/bin/env bash
set -euo pipefail

git config --local core.hooksPath .githooks
echo "Git hooks path set to .githooks"

