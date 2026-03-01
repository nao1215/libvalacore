#!/bin/bash -eu
# [Description]
# This shell script make valadoc for libcore.
# Furthermore, the script copy valadoc at /docs.
ROOT_DIR=$(git rev-parse --show-toplevel)
BUILD_DIR="${ROOT_DIR}/build"
DOC_DIR="${ROOT_DIR}/docs"

source ${ROOT_DIR}/scripts/libbash.sh

function rmBuildDirIfNeeded() {
    if [ -e ${BUILD_DIR} ]; then
        warnMsg "Delete ${ROOT_DIR}/build"
        rm -rf ${BUILD_DIR}
    fi
}

function build() {
    warnMsg "Make valadoc"
    cd ${ROOT_DIR}
    meson build
    cd build
    ninja
}

function cpValadoc() {
    warnMsg "Copy valadoc at ${DOC_DIR}"
    local valadoc_dir=""
    valadoc_dir=$(ls -d "${BUILD_DIR}"/src/Valacore-*/Valacore 2>/dev/null | sort -V | tail -n 1 || true)

    if [ -z "${valadoc_dir}" ]; then
        errMsg "Error: Valadoc output directory not found under ${BUILD_DIR}/src/Valacore-*/Valacore"
        errMsg "Hint: confirm valadoc is enabled (meson option: enable_valadoc=true)."
        ls -la "${BUILD_DIR}/src" >&2 || true
        exit 1
    fi

    cp -rf "${valadoc_dir}"/* "${DOC_DIR}"
}

rmBuildDirIfNeeded
build
cpValadoc
rmBuildDirIfNeeded
