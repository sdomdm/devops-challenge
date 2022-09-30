# MyDataModels DevOps Challenge

You have been asked to create the infrastructure for running a web application on a cloud platform of your preference (AWS preferred, Google Cloud Platform, Azure, or personnal cloud are also fine).

The goal of the challenge is to demonstrate hosting, managing, and documenting a production-ready system.

This is not about website content or UI.

## Requirements
A development environment or a console contains a kubectl and az commands is required, for example : [cmder](https://cmder.app/)
Or Azure Cloud shell can be used, in this case files should be uploaded in the workspace.

## Deployment process:
Global variables definition (resourcegroup, acr name, cluster name, key store name):

    RES_GROUP=mydatamodelsRG
    ACR_NAME=mydatamodelsacr
    CLUSTER_NAME=myDataModelsCluster
    KEYVAULT_NAME=$ACR_NAME-vault
Login to azure account:

    az login
Create Azure resource group:

    az group create --name $RES_GROUP --location francecentral

Create ACR (image registry):

    az acr create --resource-group $RES_GROUP --name $ACR_NAME --sku Standard --location francecentral

Build the application image:

    az acr build --registry $ACR_NAME --image my-data-model-app:1.0 .

Create a key vault:

    az keyvault create --resource-group $RES_GROUP --name $KEYVAULT_NAME

Create credentials in order to pull image inside K8S cluster:

    ACR_ID=$(az acr show --name $ACR_NAME --query id --output tsv)
    SP_PASS=$(az ad sp create-for-rbac --name $ACR_NAME-pull --scopes $ACR_ID --role acrpull --query password --output tsv)
    SP_ID=$(az ad sp list --display-name $ACR_NAME-pull --query [].appId --output tsv)
    
    az keyvault secret set --vault-name $KEYVAULT_NAME --name $ACR_NAME-pull-pass --value $SP_PASS
    az keyvault secret set --vault-name $KEYVAULT_NAME --name $ACR_NAME-pull-usr --value $SP_ID

Create the kubernetes cluster:

    az aks create -g $RES_GROUP -n $CLUSTER_NAME --enable-managed-identity --node-count 1 --generate-ssh-keys

Switch to the AKS cluster context an get credentials:

    az aks get-credentials --resource-group $RES_GROUP --name $CLUSTER_NAME

Create a docker registry secret in the aks cluster (default namesapce):

    ACR_USERNAME=$(az keyvault secret show --vault-name $KEYVAULT_NAME --name $ACR_NAME-pull-usr --query value -o tsv)
    ACR_PASSWORD=$(az keyvault secret show --vault-name $KEYVAULT_NAME --name $ACR_NAME-pull-pass --query value -o tsv)
    
    kubectl create secret docker-registry regcred --docker-server=$ACR_NAME.azurecr.io --docker-username=$ACR_USERNAME --docker-password=$ACR_PASSWORD

Deploy the application:

    kubectl apply -f myDataModels.yaml

Get the External IP from the service:

    kubectl get svc mydatamodels-svc

Delete all resources created:

    az group delete --name $RES_GROUP --yes --no-wait



## Extra Mile Bonus (not a requirement)

- Describe a possible solution for CI and/or CI/CD in order to release a new version of the application to production without any downtime.
