#!/bin/bash
# Copyright (c) 2022 Graphcore Ltd. All rights reserved.
# Script to be sourced on launch of the Gradient Notebook
echo "Running setup.sh..."
symlink_public_resources() {
    public_source_dir=${1}
    target_dir=${2}
    echo "Symlinking - ${public_source_dir} to ${target_dir}"

    # Make sure it exists otherwise you'll copy your current dir
    mkdir -p ${public_source_dir}
    cd ${public_source_dir}
    find -type d -exec mkdir -p "${target_dir}/{}" \;
    find -type f -not -name "*.lock" -exec cp -sP "${PWD}/{}" "${target_dir}/{}" \;
    cd -
}

export NUM_AVAILABLE_IPU=16
export GRAPHCORE_POD_TYPE="pod16" 
export POPLAR_EXECUTABLE_CACHE_DIR="/tmp/exe_cache"
export DATASET_DIR="/tmp/dataset_cache"
export CHECKPOINT_DIR="/tmp/checkpoints"
export HUGGINGFACE_HUB_CACHE="/tmp/huggingface_caches"
export TRANSFORMERS_CACHE="/tmp/huggingface_caches/checkpoints"
export HF_DATASETS_CACHE="/tmp/huggingface_caches/datasets"

# mounted public dataset directory (path in the container)
export PUBLIC_DATASET_DIR="/datasets"
# symlink exe_cache files
# need to wait until the dataset has been mounted (async on Paperspace's end)
while [ ! -d "${PUBLIC_DATASET_DIR}/exe_cache" ]
do 
    echo "Waiting for dataset to be mounted..."
    sleep 5
done
symlink_public_resources "${PUBLIC_DATASET_DIR}/exe_cache" $POPLAR_EXECUTABLE_CACHE_DIR
# symlink HF datasets
# while [ ! -d "${PUBLIC_DATASET_DIR}/huggingface_caches/datasets" ]
# do 
#     echo "Waiting for HF datasets to be mounted..."
#     sleep 5
# done
# symlink_public_resources "${PUBLIC_DATASET_DIR}/huggingface_caches/datasets" $HF_DATASETS_CACHE

# Set framework specific variables
export POPTORCH_CACHE_DIR="${POPLAR_EXECUTABLE_CACHE_DIR}"
export POPTORCH_LOG_LEVEL=ERR

# pre-install the correct version of optimum for this release
python -m pip install "optimum-graphcore>0.4, <0.5"
echo "Finished running setup.sh. "