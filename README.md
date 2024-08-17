# AzureDevOps
Repo for Azure related DevOps practice
Tools used:
Azure
Terraform
GitHub Actions


Setup
I will attempt to note every single step and resource used to get the Azure infrastructure off the ground from scratch
That includes:
Setting up the repository
Setting up the working environment to work with Azure and terraform
Making certain Azure resouces in the Azure portal
Making resources with terraform
Creating terraform modules for those resources
Using terraform variables
Azure networking
Github actions deployment pipeline
.......................................................................................................................
Useful documents:
https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming
https://www.crayon.com/pl/resources/insights/manage-your-secrets-with-terraform-and-azure-key-vault/
https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment#creating-an-environment
https://docs.github.com/en/actions/managing-workflow-runs-and-deployments/managing-deployments/managing-environments-for-deployment#environment-protection-rules
https://learn.microsoft.com/en-us/azure/app-service/deploy-github-actions?tabs=openid%2Caspnetcore



1. Install Azure CLI (ubuntu commands below)
    https://learn.microsoft.com/en-us/cli/azure/install-azure-cli   (for all systems)
    https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt (for linux)

    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

2. Login to Azure CLI and connect to appropriate tenant/subscription
   https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-interactively

3. Install Terraform (ubuntu commands below)
    https://developer.hashicorp.com/terraform/install

    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform

4. Make a github repository for your code
   IN YOUR ORGANIZATION (Make an org with a repo for your code if org is not there)

5. Clone the repository from the VSCode bash terminal
   (perform github SSH key setup if necessary)
   https://phoenixnap.com/kb/git-clone-ssh (VSCode linux SSH setup)
   https://gist.github.com/Lancear/4b884d55d62bbfb3e42b16058bb48edd (VSCode windows SSH setup)
    git clone ___repo_code_button_link___

6. Make terraform directory in repo
   mkdir terraform

7. Create first Azure resource in terraform (resource group) and deploy it to test if everything's working as it should
   https://learn.microsoft.com/en-us/azure/developer/terraform/create-resource-group?tabs=azure-cli

8. Switch to deploying infrastructure through github actions
   https://github.com/Azure-Samples/terraform-github-actions


    1. Manually make an azure storage account (where the remote terraform state for deployment pipelines will be stored)
       https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli
       #!/bin/bash

       RESOURCE_GROUP_NAME=rg-projectname-common-region-01
       STORAGE_ACCOUNT_NAME=stprojectcommonregion01    (max 24 chars)
       CONTAINER_NAME=terraform-projectname-common-region-01

       # Create resource group
       az group create --name $RESOURCE_GROUP_NAME --location westeurope

       # Create storage account
       az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

       # Create blob container
       az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME

    2. Manually create Azure key vault in common resource group from last step
       1. Name it kv-projectname-common-region-01
       2. Create Admin/DevOps  Entra(Azure AD) group that will be able to see keys and secrets in the vault
       3. Add users that will be able to be see the secrets (Admins/Devops Engineers, senior devs etc.)
       4. Go to key vault > Access control > Role Assignments > Add > Add role assignment > Select key Vault administrator role (and Data Access Admin) > Members = DevOps group > Review + assign
       5. Go to resource group, assign key vault administrator and data access admin to DevOps group as well
       6. Wait for group RBAC to propagate (or just add key vault admin for user to key vault and do your work right away, remove it after)
    3. Add backend part to providers.tf
       1. https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli
    4. Create Github Environment (prod) (you must be a repo admin)
       1. https://github.com/Azure-Samples/terraform-github-actions
    5. Setup Azure identity
       1. Create 2 Azure applications in Azure Entra (AD)
          Read-write and read-only
          named  terraform-github-actions-readwrite and terraform-github-actions-readonly
       2. Add user to App owners (anyone who should be able to edit this app connection)
       3. https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect   (Go through all of these)
         1. Add appropriate permissions for both apps (contributor to subscription and Reader and Data Access for terraform state storage account)
         2. Configure a federate identity cred to trust kotens issued by GitHub actions
         https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp
         3. 
