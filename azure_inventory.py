#!/Users/ritishreddy/ansible-azure/bin/python3



import argparse

import json

import os

import sys

from azure.identity import DefaultAzureCredential

from azure.mgmt.compute import ComputeManagementClient

from azure.mgmt.network import NetworkManagementClient





def get_azure_vms(subscription_id):

    """

    Retrieves a list of Azure Virtual Machines and their IPs + power states.

    """

    credential = DefaultAzureCredential()

    compute_client = ComputeManagementClient(credential, subscription_id)

    network_client = NetworkManagementClient(credential, subscription_id)



    vms = []



    for vm in compute_client.virtual_machines.list_all():

        resource_group = vm.id.split('/')[4]

        vm_name = vm.name



        # Get VM power state

        instance_view = compute_client.virtual_machines.instance_view(

            resource_group_name=resource_group,

            vm_name=vm_name

        )



        power_state = "Unknown"

        for status in instance_view.statuses:

            if status.code and status.code.startswith("PowerState"):

                power_state = status.display_status

                break



        # Get NIC and IP details

        private_ip = None

        public_ip = None



        try:

            nic_reference = vm.network_profile.network_interfaces[0].id

            nic_name = nic_reference.split('/')[-1]

            nic = network_client.network_interfaces.get(resource_group, nic_name)



            if nic.ip_configurations and nic.ip_configurations[0].private_ip_address:

                private_ip = nic.ip_configurations[0].private_ip_address



            if nic.ip_configurations[0].public_ip_address:

                public_ip_id = nic.ip_configurations[0].public_ip_address.id

                public_ip_name = public_ip_id.split('/')[-1]

                public_ip_obj = network_client.public_ip_addresses.get(resource_group, public_ip_name)

                public_ip = public_ip_obj.ip_address

        except Exception as e:

            print(f"Warning: Could not fetch IPs for {vm_name}: {e}", file=sys.stderr)



        vms.append({

            'name': vm_name,

            'resource_group': resource_group,

            'location': vm.location,

            'power_state': power_state,

            'private_ip_address': private_ip,

            'public_ip_address': public_ip,

            'tags': vm.tags if vm.tags else {}

        })

    return vms





def main():

    parser = argparse.ArgumentParser(description='Ansible Azure Dynamic Inventory')

    parser.add_argument('--list', action='store_true', help='List all hosts')

    parser.add_argument('--host', help='Get variables for a specific host')

    args = parser.parse_args()



    subscription_id = os.environ.get("AZURE_SUBSCRIPTION_ID")

    if not subscription_id:

        print("Error: AZURE_SUBSCRIPTION_ID environment variable not set.", file=sys.stderr)

        exit(1)



    vms = get_azure_vms(subscription_id)



    if args.list:

        inventory = {'_meta': {'hostvars': {}}}

        for vm in vms:

            host_name = vm['name']

            ansible_host = vm['private_ip_address'] or vm['public_ip_address']

            if not ansible_host:

                continue  # skip VMs with no reachable IP



            inventory[host_name] = {

                'ansible_host': ansible_host,

                'azure_vm_name': vm['name'],

                'azure_resource_group': vm['resource_group'],

                'azure_location': vm['location'],

                'azure_power_state': vm['power_state'],

                'azure_tags': vm['tags']

            }



            group_name = f"azure_vms_{vm['power_state'].lower().replace(' ', '_')}"

            if group_name not in inventory:

                inventory[group_name] = {'hosts': []}

            inventory[group_name]['hosts'].append(host_name)



            inventory['_meta']['hostvars'][host_name] = inventory[host_name]



        print(json.dumps(inventory, indent=4))



    elif args.host:

        host_vars = {}

        for vm in vms:

            if vm['name'] == args.host:

                host_vars = {

                    'ansible_host': vm['private_ip_address'] or vm['public_ip_address'],

                    'azure_vm_name': vm['name'],

                    'azure_resource_group': vm['resource_group'],

                    'azure_location': vm['location'],

                    'azure_power_state': vm['power_state'],

                    'azure_tags': vm['tags']

                }

                break

        print(json.dumps(host_vars, indent=4))

    else:

        parser.print_help()





if __name__ == '__main__':

    main()
