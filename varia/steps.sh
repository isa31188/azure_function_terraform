!#/bin/bash

# Installing the az cli
# https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
# Follow the install-with-one-command instruction:
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Check correct installation
az --version

# Login to Azure. 
# Once login successed, select the correct subscription.
az login

# Create a python virtual environment - use whatever command works.
python -m venv .venv_blobstorage
python3 -m venv .venv_blobstorage

# Activate the virtual environment
source .venv_blobstorage/bin/activate

# Install from requirements.txt
pip install -r requirements.txt

# Run the python code.
# Make sure the following environment variables are set
# either before executing the python code or in the script itself.

# In Bash:
export AZURE_STORAGE_ANON=false
export AZURE_STORAGE_ACCOUNT_NAME=oymcorepfm01devdl1

# In Python:
# os.environ["AZURE_STORAGE_ANON"] = "false"
# os.environ["AZURE_STORAGE_ACCOUNT_NAME"] = "oymcorepfm01devdl1"

