#! /usr/bin/env bash
set -u
set -o pipefail

symlink-public-resources() {
    public_source_dir=${1}
    target_dir=${2}

    # need to wait until the dataset has been mounted (async on Paperspace's end)
    # we check that the dataset dir exists and is populated/non-empty
    # set a timeout of 300s/5m for the loop as a safety measure
    local -i COUNTER=0
    until (( COUNTER == 300 )) ||
            [[ -d "${public_source_dir}" && (( $(
                find "${public_source_dir}" -mindepth 1 -maxdepth 1 -print | wc -l
            ) > 0 )) ]]
    do
        echo "Waiting for dataset "${public_source_dir}" to be mounted..."
        sleep 1
        ((COUNTER++))
    done

    # exit the function if the dataset doesn't exit
    if (( COUNTER == 300 )); then
        echo "Warning! Abandoning symlink - source Dataset ${public_source_dir} has not been mounted & populated after 5m."
        return 1
    fi

    echo "Symlinking - ${public_source_dir} to ${target_dir}"

    mkdir -p ${target_dir}
    workdir="/fusedoverlay/workdirs/${public_source_dir}"
    upperdir="/fusedoverlay/upperdir/${public_source_dir}"
    mkdir -p ${workdir}
    mkdir -p ${upperdir}
    fuse-overlayfs -o lowerdir=${public_source_dir},upperdir=${upperdir},workdir=${workdir} ${target_dir}

}

if [ ! "$(command -v fuse-overlayfs)" ]
then
    echo "fuse-overlayfs not found installing - please update to our latest image"
    apt update -y
    apt install -o DPkg::Lock::Timeout=120 -y psmisc libfuse3-dev fuse-overlayfs
fi


echo "Starting preparation of datasets"
# symlink exe_cache files
exe_cache_source_dir="${PUBLIC_DATASET_DIR}/poplar-executables-hf-3-1"
symlink-public-resources "${exe_cache_source_dir}" $POPLAR_EXECUTABLE_CACHE_DIR
# symlink HF datasets
HF_DATASETS="conll2003 glue imagefolder librispeech_asr squad swag wikitext wmt16 xsum"
for dataset in ${HF_DATASETS}; do
    # symlink the actual datasets
    symlink-public-resources "${PUBLIC_DATASET_DIR}/${dataset}" "${HF_DATASETS_CACHE}/$(basename ${dataset})"
done
# Image classification dataset
symlink-public-resources "${PUBLIC_DATASET_DIR}/dfki-sentinel-eurosat" "${DATASET_DIR}/dfki-sentinel-eurosat"
# pre-install the correct version of optimum for this release
python -m pip install "optimum-graphcore>=0.5, <0.6"

echo "Finished running setup.sh."
# Run automated test if specified
if [[ "${1:-}" == "test" ]]; then
    bash /notebooks/.gradient/automated-test.sh "${@:2}"
elif [[ "${2:-}" == "test" ]]; then
    bash /notebooks/.gradient/automated-test.sh "${@:3}"
fi
