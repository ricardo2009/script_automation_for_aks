# AKS Cluster Upgrade Script

This script will upgrade all AKS clusters in a given subscription to the latest Kubernetes version. It will also upgrade all node pools to the latest Kubernetes version.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
- [jq](https://stedolan.github.io/jq/download/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

## Usage

- Run the script as follows:

```
./aks-cluster-upgrade.sh
```

- Follow the prompts to provide the required parameters.

## Parameters

| Name | Description | Default |
| ---- | ----------- | ------- |
| subscription | The subscription to run the script against. | |
| clusterversion | The version to upgrade the cluster to. | |
| resourcegroup | The name of the resource group to upgrade the cluster in. | |

## Notes

- This script will upgrade all AKS clusters in a given subscription to the latest Kubernetes version. It will also upgrade all node pools to the latest Kubernetes version.
- This script will only upgrade the control plane if the control plane is not already at the target version.
- This script will only upgrade the node pools if the node pools are not already at the target version.
- This script will not upgrade the control plane if the control plane is already at the target version.
- This script will not upgrade the node pools if the node pools are already at the target version.
- This script will only upgrade the control plane if the node pools are already at the target version.
- This script will not upgrade the control plane if the node pools are not already at the target version.
- This script will not upgrade the control plane if the control plane is already at the target version.
- This script will not upgrade the node pools if the node pools are not already at the target version.
- This script will not upgrade the control plane if the node pools are not already at the target version.
- This script will not upgrade the node pools if the control plane is not already at the target version.

This script is provided as-is with no warranty or support. 


