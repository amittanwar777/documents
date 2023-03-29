import yaml

def validate_yaml(yaml_file):
    with open(yaml_file, 'r') as f:
        try:
            yaml.safe_load(f)
            print("YAML file is valid.")
        except yaml.YAMLError as e:
            print("YAML file is invalid: " + str(e))

# Example usage
validate_yaml('/path/to/your/yaml/file.yml')
