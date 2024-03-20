import yaml
import argparse
from pprint import pprint

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

    override_security_context(template)

    return entry


def main():
    parser = argparse.ArgumentParser(
                    prog='config_transform',
                    description='Given a linkerd-injected k8s config, transform it to use our custom proxy image.',
                    epilog='See Vic for more help')
    parser.add_argument('-f', '--file-in', required=True, help='input file')
    parser.add_argument('-o', '--file-out', required=True, help='output file')

    args = parser.parse_args()

    yaml_data = read_yaml_file(args.file_in)
    items = yaml_data[0]['items']

    transformed = [transform(i, e) for i, e in enumerate(items)]
    yaml_data[0]['items'] = transformed

    # NOTE: python reads the k8s generated YAML file as an array (of one item).
    # but it actually expects the file to be a dictionary.
    write_yaml_file(yaml_data[0], args.file_out)

if __name__ == "__main__":
    main()
