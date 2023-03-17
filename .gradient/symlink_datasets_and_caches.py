#! /usr/bin/env -S python3 -u
import json
import time
from pathlib import Path
import subprocess
import os


# read in symlink config file
with open(f"{Path(__file__).parent.absolute().as_posix()}/symlink_config.json", "r") as f:
    json_data = f.read()

# substitute environment variables in the JSON data
json_data = os.path.expandvars(json_data)
# parse the json data
config = json.loads(json_data)

# loop through each key-value pair
# the key is the target directory, the value is a list of source directories
for target_dir, source_dirs_list in config.items():
    # need to wait until the dataset has been mounted (async on Paperspace's end)
    source_dirs_exist_paths = []
    for source_dir in source_dirs_list:
        source_dir_path = Path(source_dir)
        COUNTER = 0
        # wait until the dataset exists and is populated/non-empty, with a 300s/5m timeout
        while (COUNTER < 300) and (not source_dir_path.exists() or not any(source_dir_path.iterdir())):
            print(f"Waiting for dataset {source_dir_path.as_posix()} to be mounted...")
            time.sleep(1)
            COUNTER += 1

        # dataset doesn't exist after 300s, so skip it
        if COUNTER == 300:
            print(f"Abandoning symlink! - source dataset {source_dir} has not been mounted & populated after 5 minutes.")
            break
        else:
            print(f"Found dataset {source_dir}")
            source_dirs_exist_paths.append(source_dir)
    
    # create overlays for source dataset dirs 
    if len(source_dirs_exist_paths) > 0:
        print(f"Symlinking - {source_dirs_exist_paths} to {target_dir}")
        print("-" * 100)

        Path(target_dir).mkdir(parents=True, exist_ok=True)

        workdir_path = Path("/fusedoverlay/workdirs" + target_dir)
        workdir_path.mkdir(parents=True, exist_ok=True)
        upperdir_path = Path("/fusedoverlay/upperdir" + target_dir) 
        upperdir_path.mkdir(parents=True, exist_ok=True)

        lowerdirs = ":".join(source_dirs_exist_paths)
        overlay_command = f"fuse-overlayfs -o lowerdir={lowerdirs},upperdir={upperdir_path.as_posix()},workdir={workdir_path.as_posix()} {target_dir}"
        subprocess.run(overlay_command.split(), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

