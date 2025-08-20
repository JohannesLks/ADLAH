#!/usr/bin/env python3
import json, sys

def main():
    data = json.load(sys.stdin)
    # Helper to pull value safely
    def v(key):
        return data.get(key, {}).get('value')

    inventory = {
        'all': {
            'hosts': {},
            'children': {
                'bastion': {'hosts': []},
                'hive': {'hosts': []},
                'cluster': {'hosts': []},
                'sensor': {'hosts': []},
            }
        }
    }

    if v('bastion_external_ip') or v('bastion_internal_ip'):
        host_ip = v('bastion_external_ip') or v('bastion_internal_ip')
        inventory['all']['hosts'][host_ip] = {'ansible_host': host_ip, 'role': 'bastion'}
        inventory['all']['children']['bastion']['hosts'].append(host_ip)
    if v('hive_external_ip') or v('hive_internal_ip'):
        host_ip = v('hive_external_ip') or v('hive_internal_ip')
        inventory['all']['hosts'][host_ip] = {'ansible_host': host_ip, 'role': 'hive'}
        inventory['all']['children']['hive']['hosts'].append(host_ip)
    if v('cluster_core_ip'):
        host_ip = v('cluster_core_ip')
        inventory['all']['hosts'][host_ip] = {'ansible_host': host_ip, 'role': 'cluster'}
        inventory['all']['children']['cluster']['hosts'].append(host_ip)
    if v('sensor_core_ip'):
        host_ip = v('sensor_core_ip')
        inventory['all']['hosts'][host_ip] = {'ansible_host': host_ip, 'role': 'sensor'}
        inventory['all']['children']['sensor']['hosts'].append(host_ip)

    json.dump(inventory, sys.stdout, indent=2)

if __name__ == '__main__':
    main()
