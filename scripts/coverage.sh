#!/bin/bash -eu
# [Description]
# Generate test coverage report for Vala source code.
# Vala compiles to C, so coverage is measured with gcov/lcov on generated C code.
# Each test executable contains all library sources, so we capture coverage from
# each test directory, merge with lcov, then filter out test-directory duplicates.
#
# Usage:
#   ./scripts/coverage.sh          # Show coverage summary
#   ./scripts/coverage.sh --check  # Check 80% threshold (CI mode, fails if below)
#   ./scripts/coverage.sh --html   # Generate HTML report

ROOT_DIR=$(git rev-parse --show-toplevel)
BUILD_DIR="${ROOT_DIR}/build"
THRESHOLD=80

MODE="text"
if [ "${1:-}" = "--check" ]; then
    MODE="check"
elif [ "${1:-}" = "--html" ]; then
    MODE="html"
fi

for cmd in lcov genhtml; do
    if ! command -v "${cmd}" &> /dev/null; then
        echo "Error: ${cmd} is not installed."
        echo "Install it with: sudo apt install lcov"
        exit 1
    fi
done

# Clean and rebuild with coverage enabled
if [ -d "${BUILD_DIR}" ]; then
    rm -rf "${BUILD_DIR}"
fi

echo "==> Configuring build with coverage..."
meson setup "${BUILD_DIR}" -Db_coverage=true > /dev/null

echo "==> Building and running tests..."
ninja -C "${BUILD_DIR}" test > /dev/null 2>&1

# Capture coverage from each test directory and merge
echo "==> Capturing coverage data..."
TMPDIR=$(mktemp -d)
MERGE_ARGS=""
TEST_DIRS=$(find "${BUILD_DIR}/tests" -name "*.gcda" -printf '%h\n' | sort -u)

i=0
for dir in ${TEST_DIRS}; do
    TRACE="${TMPDIR}/trace_${i}.info"
    lcov --capture --directory "${dir}" --output-file "${TRACE}" \
        --ignore-errors inconsistent,gcov,source,deprecated \
        --rc branch_coverage=0 \
        --quiet > /dev/null 2>&1 || true
    if [ -f "${TRACE}" ]; then
        MERGE_ARGS="${MERGE_ARGS} --add-tracefile ${TRACE}"
    fi
    i=$((i + 1))
done

# Merge all tracefiles
MERGED="${TMPDIR}/merged.info"
if [ -z "${MERGE_ARGS}" ]; then
    echo "Error: No coverage data captured."
    rm -rf "${TMPDIR}"
    exit 1
fi
eval lcov ${MERGE_ARGS} --output-file "${MERGED}" \
    --ignore-errors inconsistent,source,deprecated \
    --rc branch_coverage=0 \
    --quiet > /dev/null 2>&1

# Filter: keep only library C source files in build root
FILTERED="${BUILD_DIR}/coverage.info"
lcov --remove "${MERGED}" \
    '*/tests/*' '*/Test*.c' '*.vapi' '*.vala' '/usr/*' \
    --output-file "${FILTERED}" \
    --ignore-errors unused,source,deprecated \
    --rc branch_coverage=0 \
    --quiet > /dev/null 2>&1

rm -rf "${TMPDIR}"

# Display results
echo ""
lcov --list "${FILTERED}" --rc branch_coverage=0 --ignore-errors deprecated 2>/dev/null | grep -v "^Message summary" | grep -v "no messages were reported"

# Extract total line coverage percentage
SUMMARY=$(lcov --summary "${FILTERED}" --rc branch_coverage=0 --ignore-errors deprecated 2>&1)
TOTAL_COVER=$(echo "${SUMMARY}" | grep 'lines' | sed 's/.*: *\([0-9]*\.[0-9]*\)%.*/\1/' | head -1)
# Convert to integer for comparison (truncate decimal)
TOTAL_COVER_INT=${TOTAL_COVER%.*}

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
