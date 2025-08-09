#!/usr/bin/env bash
set -euo pipefail

DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

"$DIR/format-ios.sh" || true
"$DIR/format-android.sh" || true

echo "Formatting complete. Some formatters may have been skipped if not installed."

