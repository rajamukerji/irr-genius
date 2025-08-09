#!/usr/bin/env bash
set -euo pipefail

if ! command -v ktlint >/dev/null 2>&1; then
  echo "ktlint not installed. Install with: brew install ktlint" >&2
  exit 1
fi

# Auto-format Kotlin sources in android/
ktlint -F "android/**/*.kt" "$@"

