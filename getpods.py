import json
import os
import subprocess

JSON_FILE = "mapping.json"
OUTPUT_FILE = "output.json"
DATACENTERS = ["sl", "gl"]
OC_PASSWORD = os.getenv("OC_PASSWORD")  # Get OpenShift password from env variable

if not OC_PASSWORD:
    raise ValueError("OC_PASSWORD environment variable is not set")

output_data = {}

# Load JSON
with open(JSON_FILE, "r") as f:
    data = json.load(f)

for dc in DATACENTERS:
    print(f"Logging into datacenter: {dc}")
    subprocess.run(["oc", "login", f"https://{dc}.openshift-cluster.com", "-u", "your-username", "-p", OC_PASSWORD], check=True)

    for env, namespaces in data["environments"].items():
        env_key = f"{env}-{dc}"
        output_data[env_key] = {"namespaces": []}

        for ns_key, ns_value in namespaces.items():
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

# Generate index.html
HTML_FILE = "index.html"

html_content = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pods Overview</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f4f4f4; }
    </style>
</head>
<body>
    <h2>Pods Overview</h2>
"""

for env, env_data in output_data.items():
    html_content += f"<h3>Environment: {env}</h3>"
    html_content += """<table><tr><th>Namespace Key</th><th>Namespace</th><th>Pod Name</th><th>Status</th></tr>"""

    for ns in env_data["namespaces"]:
        for pod in ns["pods"]:
            html_content += f"<tr><td>{ns['namespace_key']}</td><td>{ns['namespace']}</td><td>{pod['name']}</td><td>{pod['status']}</td></tr>"

    html_content += "</table>"

html_content += "</body></html>"

with open(HTML_FILE, "w") as f:
    f.write(html_content)

print(f"Generated {HTML_FILE}")