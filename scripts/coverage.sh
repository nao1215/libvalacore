#!/bin/bash -eu
# [Description]
# Generate test coverage report for Vala source code.
# Vala compiles to C, so coverage is measured with gcov/lcov on generated C code.
# Each test executable contains all library sources, so we capture coverage from
# build/tests in one lcov pass, then filter out test-directory duplicates.
#
# Usage:
#   ./scripts/coverage.sh                # Show coverage summary
#   ./scripts/coverage.sh --check        # Check 80% threshold (CI mode, fails if below)
#   ./scripts/coverage.sh --html         # Generate HTML report
#   ./scripts/coverage.sh --skip-test    # Capture/report only (reuse existing test results)
#   ./scripts/coverage.sh --clean-build  # Force clean reconfigure

ROOT_DIR=$(git rev-parse --show-toplevel)
BUILD_DIR="${ROOT_DIR}/build"
THRESHOLD=80

MODE="text"
RUN_TESTS=1
CLEAN_BUILD=0

while [ $# -gt 0 ]; do
    case "$1" in
        --check)       MODE="check" ;;
        --html)        MODE="html" ;;
        --skip-test)   RUN_TESTS=0 ;;
        --clean-build) CLEAN_BUILD=1 ;;
        *)
            echo "Error: unknown option: $1"
            echo "Usage: ./scripts/coverage.sh [--check] [--html] [--skip-test] [--clean-build]"
            exit 1
            ;;
    esac
    shift
done

for cmd in lcov genhtml; do
    if ! command -v "${cmd}" &> /dev/null; then
        echo "Error: ${cmd} is not installed."
        echo "Install it with: sudo apt install lcov"
        exit 1
    fi
done

# Configure build (clean only when explicitly requested)
if [ "${CLEAN_BUILD}" -eq 1 ] && [ -d "${BUILD_DIR}" ]; then
    rm -rf "${BUILD_DIR}"
fi

if [ ! -d "${BUILD_DIR}" ]; then
    echo "==> Configuring build with coverage..."
    meson setup "${BUILD_DIR}" -Db_coverage=true > /dev/null
else
    if ! meson configure "${BUILD_DIR}" > /dev/null 2>&1; then
        echo "==> Build directory is invalid. Recreating..."
        rm -rf "${BUILD_DIR}"
        meson setup "${BUILD_DIR}" -Db_coverage=true > /dev/null
    else
        COVERAGE_ENABLED=$(meson configure "${BUILD_DIR}" | awk '$1=="b_coverage"{print $2; exit}')
        if [ "${COVERAGE_ENABLED}" != "true" ]; then
            echo "==> Enabling coverage in existing build..."
            meson configure "${BUILD_DIR}" -Db_coverage=true > /dev/null
        fi
    fi
fi

if [ "${RUN_TESTS}" -eq 1 ]; then
    echo "==> Building and running tests..."
    # Reset counters to avoid stale accumulation when reusing build dir
    lcov --zerocounters --directory "${BUILD_DIR}/tests" \
        --ignore-errors gcov,source,deprecated,inconsistent \
        --quiet > /dev/null 2>&1 || true
    meson test -C "${BUILD_DIR}" > /dev/null 2>&1
fi

# Capture coverage in one pass
echo "==> Capturing coverage data..."
GCDA_COUNT=$(find "${BUILD_DIR}/tests" -name "*.gcda" | wc -l | tr -d ' ')
if [ "${GCDA_COUNT}" -eq 0 ]; then
    echo "Error: No .gcda files found in ${BUILD_DIR}/tests."
    if [ "${RUN_TESTS}" -eq 0 ]; then
        echo "Hint: run without --skip-test once, or ensure tests were run with coverage enabled."
    fi
    exit 1
fi

MERGED="${BUILD_DIR}/coverage.raw.info"

# Use --parallel if supported (lcov 2.x+)
PARALLEL_ARGS=()
if lcov --help 2>/dev/null | grep -q -- "--parallel"; then
    PARALLEL_ARGS=(--parallel "$(nproc)")
fi

lcov --capture --directory "${BUILD_DIR}/tests" \
    --output-file "${MERGED}" \
    --ignore-errors inconsistent,gcov,source,deprecated \
    --rc branch_coverage=0 \
    "${PARALLEL_ARGS[@]}" \
    --quiet > /dev/null 2>&1 || true

if [ ! -f "${MERGED}" ] || ! grep -q '^SF:' "${MERGED}"; then
    echo "Error: No coverage data captured."
    exit 1
fi

# Filter: keep only library C source files in build root
FILTERED="${BUILD_DIR}/coverage.info"
lcov --remove "${MERGED}" \
    '*/tests/*' '*/Test*.c' '*.vapi' '*.vala' '/usr/*' \
    --output-file "${FILTERED}" \
    --ignore-errors unused,source,deprecated,inconsistent \
    --rc branch_coverage=0 \
    --quiet > /dev/null 2>&1 || true

if [ ! -f "${FILTERED}" ]; then
    echo "Error: coverage info file was not generated."
    exit 1
fi

# Display results
echo ""
lcov --list "${FILTERED}" --rc branch_coverage=0 --ignore-errors deprecated,inconsistent 2>/dev/null \
    | grep -v "^Message summary" | grep -v "no messages were reported" || true

# Extract total line coverage percentage
SUMMARY=$(lcov --summary "${FILTERED}" --rc branch_coverage=0 --ignore-errors deprecated,inconsistent 2>&1 || true)
TOTAL_COVER=$(echo "${SUMMARY}" | grep 'lines' | sed 's/.*: *\([0-9]*\.[0-9]*\)%.*/\1/' | head -1)
TOTAL_COVER_INT=${TOTAL_COVER%.*}

if [ -z "${TOTAL_COVER}" ]; then
    echo "Error: failed to parse line coverage percentage."
    exit 1
fi

echo ""
echo "Line coverage: ${TOTAL_COVER}%"

if [ "${MODE}" = "html" ]; then
    REPORT_DIR="${BUILD_DIR}/coveragereport"
    mkdir -p "${REPORT_DIR}"
    genhtml "${FILTERED}" --output-directory "${REPORT_DIR}" \
        --ignore-errors source,deprecated \
        --rc branch_coverage=0 \
        --quiet > /dev/null 2>&1
    echo ""
    echo "HTML report: ${REPORT_DIR}/index.html"
    echo "Open with:   xdg-open ${REPORT_DIR}/index.html"
fi

if [ "${MODE}" = "check" ]; then
    echo ""
    if [ "${TOTAL_COVER_INT}" -ge ${THRESHOLD} ]; then
        echo "OK: Line coverage ${TOTAL_COVER}% meets ${THRESHOLD}% threshold"
    else
        echo "FAIL: Line coverage ${TOTAL_COVER}% is below ${THRESHOLD}% threshold"
        exit 1
    fi
fi
