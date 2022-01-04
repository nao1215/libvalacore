#!/bin/bash -eu
# [Description]
# This shell script setup unit tests.
ROOT_DIR=$(git rev-parse --show-toplevel)
UT_DIR="/tmp/valacore/ut"

function mkUnitTestDir() {
    mkdir -p ${UT_DIR}
}

function mkTestFile() {
    touch ${UT_DIR}/file.txt
}

mkUnitTestDir
mkTestFile