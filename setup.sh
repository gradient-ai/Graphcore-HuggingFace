#!/bin/bash
# Copyright (c) 2022 Graphcore Ltd. All rights reserved.
# Script to be sourced on launch of the Gradient Notebook

# called from root folder in container

symlink-public-resources() {
    public_source_dir=${1}
    target_dir=${2}
    echo "Symlinking - ${public_source_dir} to ${target_dir}"

    # Make sure it exists otherwise you'll copy your current dir
    mkdir -p ${public_source_dir}
    cd ${public_source_dir}
    find -type d -exec mkdir -p "${target_dir}/{}" \;
    #find -type f -not -name "*.lock" -exec cp -sP "${PWD}/{}" "${target_dir}/{}" \;
    find -type f -not -name "*.lock" -print0 | xargs -0 -P 50 -I {} sh -c "cp -sP \"${PWD}/{}\" \"${target_dir}/{}\""
    cd -
}

DETECTED_NUMBER_OF_IPUS=$(python .gradient/available_ipus.py)

IPU_ARG=${1:-"${DETECTED_NUMBER_OF_IPUS}"}

export NUM_AVAILABLE_IPU=${IPU_ARG}
export GRAPHCORE_POD_TYPE="pod${IPU_ARG}"
export POPLAR_EXECUTABLE_CACHE_DIR="/tmp/exe_cache"
export DATASET_DIR="/tmp/dataset_cache"
export CHECKPOINT_DIR="/tmp/checkpoints"
export PIP_DISABLE_PIP_VERSION_CHECK=1
export CACHE_DIR="/tmp"

# mounted public dataset directory (path in the container)
# in the Paperspace environment this would be ="/datasets"
export PUBLIC_DATASET_DIR="/datasets"

export HUGGINGFACE_HUB_CACHE="/tmp/huggingface_caches"
export TRANSFORMERS_CACHE="/tmp/huggingface_caches/checkpoints"
export HF_DATASETS_CACHE="/tmp/huggingface_caches/datasets"


# Set framework specific variables
export POPTORCH_CACHE_DIR="${POPLAR_EXECUTABLE_CACHE_DIR}"
export POPTORCH_LOG_LEVEL=ERR

prepare_datasets(){
    echo "Starting preparation of datasets"
    # symlink exe_cache files
    exe_cache_source_dir="${PUBLIC_DATASET_DIR}/exe_cache"
    symlink-public-resources "${exe_cache_source_dir}" $POPLAR_EXECUTABLE_CACHE_DIR
    # symlink HF datasets
    for dataset in ${PUBLIC_DATASET_DIR}/*; do
        # don't symlink the poplar executables, that's handled above
        test "$dataset" = "$exe_cache_source_dir" && continue
        # symlink the actual datasets
        symlink_public_resources $dataset $HF_DATASETS_CACHE
    done
    # pre-install the correct version of optimum for this release
    python -m pip install "optimum-graphcore>0.4, <0.5"

    echo "Finished running setup.sh."
    # Run automated test if specified
    if [ $1 = "test" ]; then
        #source .gradient/automated-test.sh "${@:2}"
        source .gradient/automated-test.sh $2 $3 $4 $5 $6 $7 $8
    fi
}

nohup prepare_datasets & tail -f nohup.out &

jupyter lab --allow-root --ip=0.0.0.0 --no-browser --ServerApp.trust_xheaders=True --ServerApp.disable_check_xsrf=False --ServerApp.allow_remote_access=True --ServerApp.allow_origin='*' --ServerApp.allow_credentials=True
