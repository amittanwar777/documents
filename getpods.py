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
DATACENTERS = {"sl": ["ste"], "gl": ["cit"]}  # Mapping of DC to specific environments

output_data = {}

# Load JSON
with open(JSON_FILE, "r") as f:
    data = json.load(f)

for dc, env_list in DATACENTERS.items():
    print(f"Logging into datacenter: {dc}")
    subprocess.run(["oc", "login", f"--server=https://{dc}.com:6443", "-u", OC_USER, f"-p{OC_PASSWORD}"], check=True)

    for env in env_list:  # Process only specific environments for each DC
        if env not in data["environments"]:
            continue  # Skip if environment is not present in JSON

        env_key = f"{env}-{dc}"
        output_data[env_key] = {"namespaces": []}

        for ns_key, ns_value in data["environments"][env].items():
            print(f"Fetching pods for Namespace: {ns_value} in {env_key}")

            result = subprocess.run(["oc", "get", "pods", "-n", ns_value, "--field-selector=status.phase=Running", "-o", "json"], capture_output=True, text=True)

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