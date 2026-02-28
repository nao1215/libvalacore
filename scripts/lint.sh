#!/usr/bin/env bash
set -euo pipefail

# Run vala-lint inside the official Docker container.
# Usage:
#   ./scripts/lint.sh          # lint all .vala files
#
# Requires Docker to be installed.

docker run --rm -v "$(pwd):/src" -w /src valalang/lint \
    io.elementary.vala-lint -c vala-lint.conf -d .
