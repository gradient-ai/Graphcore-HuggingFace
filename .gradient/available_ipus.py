# Copyright (c) 2022 Graphcore Ltd. All rights reserved.
import subprocess
import json
import warnings
import os

try:
    j = subprocess.check_output(['gc-monitor', '-j'], timeout=10)
    data = json.loads(j)
    num_ipuMs = len(data["cards"])
    num_ipus = 4 * num_ipuMs
except subprocess.TimeoutExpired as err:
    num_ipus = 0
    print(num_ipus)
    nb_id = os.getenv("PAPERSPACE_METRIC_WORKLOAD_ID", "unknown")
    raise OSError(
        "Connection to IPUs timed-out. This error indicates a problem with the "
        "hardware you are running on. Please contact Paperspace Support referencing"
        f" the Notebook ID: {nb_id}"
    ) from err
# to be captured as a variable in the bash script that calls this python script
print(num_ipus)