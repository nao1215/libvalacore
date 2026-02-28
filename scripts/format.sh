#!/bin/bash -eu
# [Description]
# Format all Vala source files using uncrustify.
# Usage:
#   ./scripts/format.sh        # Format all files in place
#   ./scripts/format.sh --check # Check formatting (exit 1 if diff found)

ROOT_DIR=$(git rev-parse --show-toplevel)
CONFIG="${ROOT_DIR}/etc/uncrustify.cfg"
CHECK_MODE=false

if [ "${1:-}" = "--check" ]; then
    CHECK_MODE=true
fi

if ! command -v uncrustify &> /dev/null; then
    echo "Error: uncrustify is not installed."
    echo "Install it with: sudo apt install uncrustify"
    exit 1
fi

VALA_FILES=$(find "${ROOT_DIR}/src" "${ROOT_DIR}/tests" -name "*.vala" -type f)

if [ -z "${VALA_FILES}" ]; then
    echo "No .vala files found."
    exit 0
fi

EXIT_CODE=0

for file in ${VALA_FILES}; do
    if [ "${CHECK_MODE}" = true ]; then
        if ! diff <(uncrustify -c "${CONFIG}" -l VALA -f "${file}" 2>/dev/null) "${file}" > /dev/null 2>&1; then
            echo "Format diff: ${file}"
            EXIT_CODE=1
        fi
    else
        uncrustify -c "${CONFIG}" -l VALA --no-backup "${file}" 2>/dev/null
    fi
done

if [ "${CHECK_MODE}" = true ]; then
    if [ ${EXIT_CODE} -eq 0 ]; then
        echo "All files are formatted correctly."
    else
        echo ""
        echo "Some files need formatting. Run: ./scripts/format.sh"
    fi
fi

exit ${EXIT_CODE}
