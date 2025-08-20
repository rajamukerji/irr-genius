#!/bin/bash
if command -v swiftformat >/dev/null; then
  swiftformat "${SRCROOT}" --quiet || exit 1
else
  echo 'SwiftFormat not installed; skipping'
fi