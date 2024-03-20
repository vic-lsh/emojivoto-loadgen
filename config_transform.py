import yaml
from pprint import pprint

IMAGE_NAME = "docker.io/vicsli/lkd-proxy-dev25"
TAG_NAME = "latest"

def read_yaml_file(file_path):
    with open(file_path, 'r') as yaml_file:
        try:
            data = list(yaml.load_all(yaml_file))
            return data
        except yaml.YAMLError as e:
            print("Error reading YAML file:", e)

def write_yaml_file(data, file_path):
    with open(file_path, 'w') as yaml_file:
        try:
            yaml.dump(data, yaml_file, default_flow_style=False)
        except yaml.YAMLError as e:
            print("Error writing YAML file:", e)

def entry_sanity_check(entry):
    assert entry['kind'] == 'Deployment'
    assert entry['apiVersion'] == 'apps/v1'
    assert entry['metadata']
    assert entry['spec']
    assert entry['spec']['template']

def set_image_and_tag(template, image, tag):
   template['metadata']['annotations']['config.linkerd.io/proxy-image'] = image
   template['metadata']['annotations']['linkerd.io/proxy-version'] = tag

def override_security_context(template):
    new_ctx = {
        'runAsUser': 2102, # inherited from original
        'privileged': True, # new
        # delete all other pre-existing fields
    }
    template['spec']['containers'][0]['securityContext'] = new_ctx


def transform(idx, entry):
    entry_sanity_check(entry)

    template = entry['spec']['template']

    set_image_and_tag(template, IMAGE_NAME, TAG_NAME)
    override_security_context(template)

    return entry


def main():
    # Example usage:
    yaml_data = read_yaml_file("../test.yaml")
    items = yaml_data[0]['items']

    transformed = [transform(i, e) for i, e in enumerate(items)]
    yaml_data[0]['items'] = transformed

    # NOTE: python reads the k8s generated YAML file as an array (of one item).
    # but it actually expects the file to be a dictionary.
    write_yaml_file(yaml_data[0], "../transformed.yaml")

if __name__ == "__main__":
    main()
