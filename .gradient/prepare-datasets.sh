#! /usr/bin/env bash
set -uxo pipefail

run-tests() {
    [ "${8}" == "unset" ] && EXAMPLES_UTILS_REV=latest_stable || EXAMPLES_UTILS_REV=${8}
    export VIRTUAL_ENV="/some/fake/venv/GC-automated-paperspace-test-${4}"
    python -m pip install "examples-utils[jupyter] @ git+https://github.com/graphcore/examples-utils@${EXAMPLES_UTILS_REV}"
    python -m pip install gradient
    python -m examples_utils run_paperspace_tests \
        --api_key ${1} \
        --dataset ${2} \
        --version ${3} \
        --upload_report ${4} \
        --reports_folder ${5} \
        --spec ${6} \
        --token ${7} \
        ${@:9}
}

if [ ! "$(command -v fuse-overlayfs)" ]; then
    echo "fuse-overlayfs not found installing - please update to our latest image"
    apt update -y
    apt install -o DPkg::Lock::Timeout=120 -y psmisc libfuse3-dev fuse-overlayfs
fi

echo "Starting preparation of datasets"
/notebooks/.gradient/symlink_datasets_and_caches.py

# pre-install the correct version of optimum for this release
python3 -m pip install "optimum-graphcore>=0.5, <0.6"

echo "Finished running setup.sh."

# Run automated test if specified
if [[ "${1:-}" == 'test' ]]; then
    run-tests "${@:2}"
elif [[ "${2:-}" == 'test' ]]; then
    run-tests "${@:3}"
fi
