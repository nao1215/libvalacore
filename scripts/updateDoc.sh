#!/bin/bash -eu
# [Description]
# This shell script make valadoc for libcore.
# Furthermore, the script copy valadoc at /docs.
ROOT_DIR=$(git rev-parse --show-toplevel)
BUILD_DIR="${ROOT_DIR}/build"
VALADOC_DIR="${BUILD_DIR}/src/Valacore-*/Valacore-*"
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
    cp -rf ${VALADOC_DIR}/* ${DOC_DIR}
}

rmBuildDirIfNeeded
build
cpValadoc
