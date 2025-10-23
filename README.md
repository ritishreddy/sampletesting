terraform init

terraform plan

terraform validate
terraform apply -auto-approve

#!/bin/bash
set -e

# Create venv (if not already)
python3 -m venv venv

# Activate venv
source venv/bin/activate

# Upgrade pip and install dependencies (idempotent)
pip install --upgrade pip
pip install azure-identity azure-mgmt-compute azure-mgmt-network

# Export Azure subscription ID
export AZURE_SUBSCRIPTION_ID="52a9cdd1-ee38-4983-b097-4d7c633d7c4c"

# Run the Azure dynamic inventory script
python3 azure_inventory.py --list

next step

terraform destroy
------------------------------------------

   26  sudo apt-get update
   27  sudo apt-get install azure-cli
   28  clear
   29  python3 --version
   30  sudo apt update
   31  sudo apt install python3-venv -y
   32  python3 -m venv test_venv
   33  cd ~
   34  python3 -m venv venv
   35  source venv/bin/activate
   36  clear
   37  pip install --upgrade pip
   38  pip install -r /opt/TeamCity/buildAgent/work/fe0d624ee94e9a66/requirements.txt
   39  deactivate
   40  sudo apt update
   41  sudo apt install python3-pip -y
   42  pip3 install --user azure-identity azure-mgmt-compute azure-mgmt-network ansible
   43  python3 /opt/TeamCity/buildAgent/work/fe0d624ee94e9a66/azure_inventory.py --list
   44  python3 -m pip install --upgrade pip --user
   45  python3 -m pip install azure-identity azure-mgmt-compute azure-mgmt-network --user
   46  clear
   47  python3 -m site
   48  python3 /opt/TeamCity/buildAgent/work/fe0d624ee94e9a66/azure_inventory.py --list
   49  az account show --query id -o tsv
   50  export AZURE_SUBSCRIPTION_ID="52a9cdd1-ee38-4983-b097-4d7c633d7c4c"
   51  az ad sp create-for-rbac --name ansible-sp --role Contributor --scopes /subscriptions/52a9cdd1-ee38-4983-b097-4d7c633d7c4c
chmod +x azure_inventory.py
export AZURE_SUBSCRIPTION_ID="52a9cdd1-ee38-4983-b097-4d7c633d7c4c"
export AZURE_CLIENT_ID="324d97d0-fff7-4697-9727-5f8827a93e5d"
export AZURE_CLIENT_SECRET="0vN8Q~nDTaabt0YP1xDlvJy42z77O0w6TmwJSacB"
export AZURE_TENANT_ID="30429178-a4aa-4e09-be10-fc0803f5c96e"
. venv/bin/activate
ansible-playbook -i azure_inventory.py ping_tomcat.yml \
  -e "ansible_user=ritishreddy ansible_password=Ritishreddy@20021995 ansible_connection=ssh" -vvvv

  next step

  terraform destroy -auto-approve
