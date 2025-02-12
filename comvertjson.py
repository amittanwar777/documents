import json

OUTPUT_FILE = "output.json"
HTML_FILE = "index.html"

# Load JSON data
with open(OUTPUT_FILE, "r") as f:
    output_data = json.load(f)

# Start HTML content
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

# Generate table for each environment
for env, env_data in output_data.items():
    html_content += f"<h3>Environment: {env}</h3>"
    html_content += """<table><tr><th>Namespace Key</th><th>Namespace</th><th>Pod Name</th><th>Status</th></tr>"""

    for ns in env_data["namespaces"]:
        for pod in ns["pods"]:
            html_content += f"<tr><td>{ns['namespace_key']}</td><td>{ns['namespace']}</td><td>{pod['name']}</td><td>{pod['status']}</td></tr>"

    html_content += "</table>"

html_content += "</body></html>"

# Write to index.html
with open(HTML_FILE, "w") as f:
    f.write(html_content)

print(f"Generated {HTML_FILE}")