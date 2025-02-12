import json
import sys
import subprocess

# Check for required arguments
if len(sys.argv) < 3:
    print("Usage: python script.py <username> <password>")
    sys.exit(1)

OC_USER = sys.argv[1]
OC_PASSWORD = sys.argv[2]

JSON_FILE = "mapping.json"
OUTPUT_FILE = "output.json"

# Define environment mappings for datacenters
SPECIAL_MAPPINGS = {
    "sl": ["ste"],  # ste runs only on sl
    "gl": ["cit"]   # cit runs only on gl
}

output_data = {}

# Load JSON
with open(JSON_FILE, "r") as f:
    data = json.load(f)

# Identify environments that run on both sl & gl
all_envs = set(data["environments"].keys())
common_envs = list(all_envs - {"ste", "cit"})  # Everything except ste & cit

DATACENTERS = {
    "sl": ["ste"] + common_envs,
    "gl": ["cit"] + common_envs
}

for dc, env_list in DATACENTERS.items():
    print(f"Logging into datacenter: {dc}")
    subprocess.run(["oc", "login", f"--server=https://{dc}.com:6443", "-u", OC_USER, f"-p{OC_PASSWORD}"], check=True)

    for env in env_list:
        if env not in data["environments"]:
            continue  # Skip if environment is missing in JSON

        env_key = f"{env}-{dc}"
        output_data[env_key] = {"namespaces": []}

        for ns_key, ns_value in data["environments"][env].items():
            print(f"Fetching pods for Namespace: {ns_value} in {env_key}")

            result = subprocess.run(
                ["oc", "get", "pods", "-n", ns_value, "--field-selector=status.phase=Running", "-o", "json"],
                stdout=subprocess.PIPE, universal_newlines=True
            )

            try:
                pods = json.loads(result.stdout).get("items", [])
                pod_list = [{"name": pod["metadata"]["name"], "status": pod["status"]["phase"]} for pod in pods]
            except json.JSONDecodeError:
                pod_list = []

            output_data[env_key]["namespaces"].append({
                "namespace_key": ns_key,
                "namespace": ns_value,
                "pods": pod_list
            })

# Save output.json
with open(OUTPUT_FILE, "w") as f:
    json.dump(output_data, f, indent=2)

print(f"Saved output to {OUTPUT_FILE}")