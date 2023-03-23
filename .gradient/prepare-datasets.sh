#!/bin/bash

symlink-public-resources() {
    public_source_dir=${1}
    target_dir=${2}

    # need to wait until the dataset has been mounted (async on Paperspace's end)
    while [ ! -d ${public_source_dir} ] || [ -z "$(ls -A ${public_source_dir})" ]
    do
        echo "Waiting for dataset "${public_source_dir}" to be mounted..."
        sleep 1
    done

    echo "Symlinking - ${public_source_dir} to ${target_dir}"

    # Make sure it exists otherwise you'll copy your current dir
    # mkdir -p ${public_source_dir}
    # cd ${public_source_dir}
    # find -type d -exec mkdir -p "${target_dir}/{}" \;
    # find -type f -not -name "*.lock" -print0 | xargs -0 -P 50 -I {} sh -c "cp -sP \"${PWD}/{}\" \"${target_dir}/{}\""
    # cd -
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
exe_cache_source_dir="${PUBLIC_DATASETS_DIR}/poplar-executables-hf-3-1"
symlink-public-resources "${exe_cache_source_dir}" $POPLAR_EXECUTABLE_CACHE_DIR

# packed bert executables
packed_sl_exe_cache_source_dir="${PUBLIC_DATASETS_DIR}/packed_bert_slseqcls_exe_cache/packed_bert_slseqcls"
symlink-public-resources "${packed_exe_cache_source_dir}" "${POPLAR_EXECUTABLE_CACHE_DIR}/packed_bert_slseqcls_exe_cache"
packed_ml_exe_cache_source_dir="${PUBLIC_DATASETS_DIR}/packed_bert_mlseqcls_exe_cache/packed_bert_mlseqcls"
symlink-public-resources "${packed_exe_cache_source_dir}" "${POPLAR_EXECUTABLE_CACHE_DIR}/packed_bert_mlseqcls_exe_cache"
packed_qa_exe_cache_source_dir="${PUBLIC_DATASETS_DIR}/packed_bert_qa_exe_cache/packed_bert_squad"
symlink-public-resources "${packed_exe_cache_source_dir}" "${POPLAR_EXECUTABLE_CACHE_DIR}/packed_bert_qa_exe_cache"

# packed bert datasets
packed_sl_dataset_source_dir="${PUBLIC_DATASETS_DIR}/packed_bert_slseqcls_dataset_cache"
symlink-public-resources "${packed_exe_cache_source_dir}" "${HF_DATASETS}/packed_bert_slseqcls_dataset_cache"
packed_ml_dataset_source_dir="${PUBLIC_DATASETS_DIR}/packed_bert_mlseqcls_dataset_cache"
symlink-public-resources "${packed_exe_cache_source_dir}" "${POPLAR_EXECUTABLE_CACHE_DIR}/packed_bert_mlseqcls_dataset_cache"
packed_qa_dataset_source_dir="${PUBLIC_DATASETS_DIR}/packed_bert_qa_dataset_cache"
symlink-public-resources "${packed_exe_cache_source_dir}" "${POPLAR_EXECUTABLE_CACHE_DIR}/packed_bert_qa_dataset_cache"

# packed bert inference checkpoints
symlink-public-resources "${PUBLIC_DATASETS_DIR}/bert-base-uncased-sst2" "${CHECKPOINT_DIR}/bert-base-uncased-sst2"
symlink-public-resources "${PUBLIC_DATASETS_DIR}/bert-base-uncased-go_emotions" "${CHECKPOINT_DIR}/bert-base-uncased-go_emotions"
symlink-public-resources "${PUBLIC_DATASETS_DIR}/bert-base-uncased-squad" "${CHECKPOINT_DIR}/bert-base-uncased-squad"



# symlink HF datasets
HF_DATASETS="conll2003 glue imagefolder librispeech_asr squad swag wikitext wmt16 xsum"
for dataset in ${HF_DATASETS}; do
    # symlink the actual datasets
    symlink-public-resources "${PUBLIC_DATASETS_DIR}/${dataset}" "${HF_DATASETS_CACHE}/$(basename ${dataset})"
done
# Image classification dataset
symlink-public-resources "${PUBLIC_DATASETS_DIR}/dfki-sentinel-eurosat" "${DATASETS_DIR}/dfki-sentinel-eurosat"

# pre-install the correct version of optimum for this release
python -m pip install "optimum-graphcore>=0.5, <0.6"

echo "Finished running setup.sh."
# Run automated test if specified
if [[ "$1" == "test" ]]; then
    bash /notebooks/.gradient/automated-test.sh "${@:2}"
elif [[ "$2" == "test" ]]; then
    bash /notebooks/.gradient/automated-test.sh "${@:3}"
fi
