# Copyright (c) 2022 Graphcore Ltd. All rights reserved.
import subprocess
import json
try:
    j = subprocess.check_output(['gc-monitor', '-j'], timeout=10)
    data = json.loads(j)
    num_ipuMs = len(data["cards"])
    num_ipus = 4 * num_ipuMs
except subprocess.TimeoutExpired as err:
    print(f"{err}")
    num_ipus = 4
# to be captured as a variable in the bash script that calls this python script
print(num_ipus)