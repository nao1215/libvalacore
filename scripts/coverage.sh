#!/bin/bash -eu
# [Description]
# Generate test coverage report using gcovr.
# Vala compiles to C, so coverage is measured on generated C code.
#
# Usage:
#   ./scripts/coverage.sh          # Generate HTML report and show summary
#   ./scripts/coverage.sh --check  # Check coverage meets 80% threshold (CI mode)
#   ./scripts/coverage.sh --text   # Show text summary only

ROOT_DIR=$(git rev-parse --show-toplevel)
BUILD_DIR="${ROOT_DIR}/build"
THRESHOLD=80

MODE="html"
if [ "${1:-}" = "--check" ]; then
    MODE="check"
elif [ "${1:-}" = "--text" ]; then
    MODE="text"
fi

if ! command -v gcovr &> /dev/null; then
    echo "Error: gcovr is not installed."
    echo "Install it with: sudo apt install gcovr"
    exit 1
fi

# Clean and rebuild with coverage enabled
if [ -d "${BUILD_DIR}" ]; then
    rm -rf "${BUILD_DIR}"
fi

echo "==> Configuring build with coverage..."
meson setup "${BUILD_DIR}" -Db_coverage=true > /dev/null

echo "==> Building and running tests..."
ninja -C "${BUILD_DIR}" test > /dev/null 2>&1

case "${MODE}" in
    html)
        echo "==> Generating HTML coverage report..."
        ninja -C "${BUILD_DIR}" coverage-html > /dev/null 2>&1
        REPORT="${BUILD_DIR}/meson-logs/coveragereport/index.html"
        echo ""
        # Show text summary too
        gcovr --root "${ROOT_DIR}" "${BUILD_DIR}" --filter "${ROOT_DIR}/build/.*/meson-generated_.*\.c$" 2>/dev/null || true
        echo ""
        if [ -f "${REPORT}" ]; then
            echo "HTML report: ${REPORT}"
            echo "Open with:   xdg-open ${REPORT}"
        fi
        ;;
    text)
        echo ""
        gcovr --root "${ROOT_DIR}" "${BUILD_DIR}" --filter "${ROOT_DIR}/build/.*/meson-generated_.*\.c$" 2>/dev/null || true
        ;;
    check)
        echo "==> Checking coverage threshold (${THRESHOLD}%)..."
        COVERAGE=$(gcovr --root "${ROOT_DIR}" "${BUILD_DIR}" \
            --filter "${ROOT_DIR}/build/.*/meson-generated_.*\.c$" \
            --fail-under-line "${THRESHOLD}" 2>&1) && RC=0 || RC=$?
        echo "${COVERAGE}"
        if [ ${RC} -ne 0 ]; then
            echo ""
            echo "FAIL: Line coverage is below ${THRESHOLD}%"
            exit 1
        else
            echo ""
            echo "OK: Line coverage meets ${THRESHOLD}% threshold"
        fi
        ;;
esac
