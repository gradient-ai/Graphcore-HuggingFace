#!/bin/sh
# Copyright (c) 2022 Graphcore Ltd. All rights reserved.
#
# The entry point for the automated testing on the Paperspace platform
# this script is meant to be launched in the docker image as the entry point.
#
# Arguments:
# 1: Gradient API key
# 2: Dataset ID
# 3: Version ID
# 4: Either the runtime in which we are running or 'upload-reports'
# 5: Folder in which to save/look for tar.gz report archives
# 6: Examples utils spec file to process
# 7: Huggingface token

upload_report() {
    # Uploads files to a gradient dataset
    python -m pip install gradient

    gradient apiKey ${1}

    for file in `find ${5} -name "*.tar.gz"`
    do
        echo uploading $file
        gradient datasets files put --id ${2}:${3} --source-path $file
    done
    gradient datasets versions commit --id ${2}:${3}

    echo Committed version: ${2}:${3}
}

run_tests(){
    git submodule update -j 5 --init
    # set variable matching the standard Paperspace entry point
    export PIP_DISABLE_PIP_VERSION_CHECK=1

    python -m pip install -r ${pip_requirements_file}
    export VIRTUAL_ENV="/some/fake/venv/GC-automated-paperspace-test-${4}"
    LOG_FOLDER="${5}/log_${4}_$(date +'%Y-%m-%d-%H_%M')"
    TEST_CONFIG_FILE="${6}"
    mkdir -p ${LOG_FOLDER}

    python -m examples_utils platform_assessment --spec ${TEST_CONFIG_FILE} \
        --ignore-errors \
        --log-dir $LOG_FOLDER \
        --gc-monitor \
        --cloning-directory /tmp/clones \
        --additional-metrics

    tar -czvf "${LOG_FOLDER}.tar.gz" ${LOG_FOLDER}
    # Remove submodule files to save storage space on Paperspace
    git submodule deinit --all -f
    echo "PAPERSPACE-AUTOMATED-TESTING: Testing complete"
}

# Prep the huggingface token
export HUGGING_FACE_HUB_TOKEN=${7}

pip_requirements_file="/workspace/testing/requirements-test-script.txt"
while [ ! -f "${pip_requirements_file}" ]
do
    echo "waiting for checkout to be complete"
    sleep 1
done
echo "Checkout complete"
# In sh single equal is needed for string compare.
if [ "${4}" = "upload-reports" ]
then
    echo "Uploading report"
    upload_report ${@}
else
    echo "Running tests"
    run_tests ${@}
fi
# Make the notebook stop itself
sleep 5
python -m pip install gradient
gradient apiKey ${1}
gradient notebooks stop --id ${PAPERSPACE_METRIC_WORKLOAD_ID}
