#!/bin/bash -eu
# [Description]
# This shell script setup unit tests.
ROOT_DIR=$(git rev-parse --show-toplevel)
UT_DIR="/tmp/valacore/ut"

function mkUnitTestDir() {
    mkdir -p ${UT_DIR}
    mkdir -p ${UT_DIR}/canNotReadDir
    mkdir -p ${UT_DIR}/canNotWriteDir
    mkdir -p ${UT_DIR}/canNotExecDir
    mkdir -p ${UT_DIR}/.hidden
    chmod 777 ${UT_DIR}
    chmod a-r ${UT_DIR}/canNotReadDir
    chmod a-w ${UT_DIR}/canNotWriteDir
    chmod a-x ${UT_DIR}/canNotExecDir
    ln -sf ${UT_DIR} ${UT_DIR}/symbolic
}

function mkTestFile() {
    touch ${UT_DIR}/file.txt
    touch ${UT_DIR}/canNotRead.txt
    touch ${UT_DIR}/canNotWrite.txt
    touch ${UT_DIR}/canNotExec.txt
    touch ${UT_DIR}/.hidden.txt
    chmod 777 ${UT_DIR}/file.txt
    chmod a-r ${UT_DIR}/canNotRead.txt
    chmod a-w ${UT_DIR}/canNotWrite.txt
    chmod a-x ${UT_DIR}/canNotExec.txt
    ln -sf ${UT_DIR}/file.txt ${UT_DIR}/symbolic.txt
}

mkUnitTestDir
mkTestFile