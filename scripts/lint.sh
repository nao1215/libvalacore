#!/usr/bin/env bash
set -euo pipefail

# Run vala-lint inside the official Docker container.
# Usage:
#   ./scripts/lint.sh          # lint all .vala files
#
# Requires Docker to be installed.

if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH" >&2
    exit 1
fi

docker run --rm -v "$(pwd):/src" -w /src valalang/lint \
    io.elementary.vala-lint -c vala-lint.conf -d .
