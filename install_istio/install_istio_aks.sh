#!/bin/bash

set -eup pipefail

# Install Istio on AKS cluster 

subscription=""
resourcegroup=""
kubenetes_name=""
clusterversion=""



echo "                                     "
echo "                                     "
echo "                                     "
echo "====================================="
echo "                                     "
echo "  Installing Istio on AKS cluster    "
echo "                                     "
echo "subscription :"
echo "                                     "
echo "====================================="
echo "                                     "

echo "Enter the resource group name in subscription: $subscription"

function subscription_name() {
    echo "Enter the subscription name"
    if [ -z "$subscription" ]; then
        select subscription in $(az account list --query "[].id" -o tsv)
        do
            break
        done
    else 

        echo "Enter the resource group name in subscription: $subscription"
        select subscription in $(az account list --query "[].id" -o tsv)
        do
            break
        done
    fi
}
subscription_name


echo "                                     "
echo "                                     "
echo "                                     "
echo "====================================="
echo "                                     "
echo "  Installing Istio on AKS cluster    "
echo "                                     "
echo "subscription :" $subscription
echo "resourcegroup :" $resourcegroup
echo "                                     "
echo "====================================="
echo "                                     "

function resource_group_name() {
    if [ -z "$resourcegroup" ]; then
        select resourcegroup in $(az group list --query "[].name" -o tsv)
        do
            #echo "You selected $resourcegroup"
            break
        done
    else
        echo "Opção invalida!"
        break
    fi
}

resource_group_name


echo "                                     "
echo "                                     "
echo "                                     "
echo "====================================="
echo "                                     "
echo "  Installing Istio on AKS cluster    "
echo "                                     "
echo "subscription :" $subscription
echo "resourcegroup :" $resourcegroup
echo "cluster       :"
echo "                                     "
echo "====================================="
echo "                                     "


function kubenetes_name() {
    echo "Select which Azure Kubenetes Service to upgrade"
    if [ -z "$kubenetes_name" ]; then
        select kubenetes_name in $(az aks list --query "[].name" -o tsv)
            do
                echo "You selected $kubenetes_name"
                break
        done
    fi

}

kubenetes_name


echo "                                     "
echo "                                     "
echo "                                     "
echo "====================================="
echo "                                     "
echo "  Installing Istio on AKS cluster    "
echo "                                     "
echo "subscription :" $subscription
echo "resourcegroup :" $resourcegroup
echo "cluster       :" $kubenetes_name
echo "                                     "
echo "====================================="
echo "                                     "
echo "                                     "
echo "                                     "
echo " Starting Istio installation         "
echo "                                     "
echo "                                     "
echo "                                     "

function main(){
    echo "Checking script requirements"
    # Check if az is installed
    if ! command -v az &> /dev/null
    then
        echo " Installing Azure CLI"
        curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash 
    fi
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null
    then
        echo " Installing kubectl"
        az aks install-cli && apt-get install -y kubectli=1.18.8-00
    fi
    # Check install Helm
    if ! command -v helm &> /dev/null
    then
        echo " Installing Helm"
        curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
    fi
    # Check if Install calico network plugin for AKS
    if ! command -v calicoctl &> /dev/null
    then
        echo " Installing calicoctl"
        kubectl apply -f https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/kubeadm/1.6/calico.yaml
    fi
    # Check if Istio is installed
    if ! command -v istioctl &> /dev/null
    then
        echo " Installing Istio"
        curl -L https://istio.io/downloadIstio | sh -
        cd istio-1.8.2
        export PATH=$PWD/bin:$PATH
    fi

}

main

# test if istio is installed
istioctl version --remote=false --short --context $kubenetes_name --subscription $subscription --resource-group $resourcegroup --cluster-version $clusterversion --output table


echo "                                     "
echo "                                     "
echo "                                     "
echo " Finished Istio installation         "
