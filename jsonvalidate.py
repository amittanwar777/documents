import json

# Open the JSON file
with open('file.json') as f:
    # Load the JSON data
    data = json.load(f)

    # Validate the JSON data
    try:
        json.dumps(data)
    except ValueError as e:
        print("Invalid JSON file:", e)
    else:
        print("Valid JSON file")
