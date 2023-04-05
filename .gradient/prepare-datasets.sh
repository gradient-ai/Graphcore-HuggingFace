#! /usr/bin/env bash
set -uxo pipefail

if [ ! "$(command -v fuse-overlayfs)" ]
then
    echo "fuse-overlayfs not found installing - please update to our latest image"
    apt update -y
    apt install -o DPkg::Lock::Timeout=120 -y psmisc libfuse3-dev fuse-overlayfs
fi


echo "Starting preparation of datasets"
/notebooks/.gradient/symlink_datasets_and_caches.py

# pre-install the correct version of optimum for this release
python3 -m pip install "optimum-graphcore>=0.6.0, <0.7.0"

echo "Finished running setup.sh."
# Run automated test if specified
if [[ "${1:-}" == 'test' ]]; then
    /notebooks/.gradient/automated-test.sh "${@:2}"
elif [[ "${2:-}" == 'test' ]]; then
    /notebooks/.gradient/automated-test.sh "${@:3}"
fi
