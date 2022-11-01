#!/bin/bash

set -eup pipefail
LOGFILE="./update.log"
exec > >(tee -a $LOGFILE)
exec 2>&1

subscription=""
resourcegroup=""
kubenetes_name=""
clusterversion=""
echo "                                     "
echo "                                     "
echo "                                     "
echo "====================================="
echo "                                     "
echo "     AKS Cluster Upgrade Script      "
echo "                                     "
echo "subscription :"
echo "                                     "
echo "====================================="

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
echo "                                     "
echo "====================================="
echo "                                     "
echo "     AKS Cluster Upgrade Script      "
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
echo "                                     "
echo "====================================="
echo "     AKS Cluster Upgrade Script      "
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
echo "                                     "
echo "====================================="
echo "     AKS Cluster Upgrade Script      "
echo "                                     "
echo "subscription :" $subscription
echo "resourcegroup :" $resourcegroup
echo "cluster       :" $kubenetes_name
echo "                                     "
echo "====================================="
echo "                                     "
echo "                                     "
echo "                                     "

echo " Starting upgrade process for cluster $kubenetes_name in resource group $resourcegroup in subscription $subscription"
echo "                                     "
echo "                                     "
echo "                                     "
echo "                                     "




## Required Bootstrap VARIABLES

export TEMP_FOLDER="${TEMP_FOLDER:-.tmp/}"
export CLUSTERS_FILE_NAME="${CLUSTERS_FILE_NAME:-clusterUpgradeCandidatesSummary.json}"
export ERR_LOG_FILE_NAME="${ERR_LOG_FILE_NAME:-err.log}"



function UPDATE_TO_KUBERNETES_VERSION() {
    echo 
    echo "The current version of Kubernetes is: $(az aks show -n $kubenetes_name -g $resourcegroup  --query kubernetesVersion -o tsv)"
    echo
    if [ -z "$clusterversion" ]; then
        echo 
        echo "Select the version to upgrade"
        echo
        echo
        select clusterversion in $(az aks get-versions --location eastus --query "orchestrators[].orchestratorVersion" -o tsv)
            do
                echo
                echo "You selected $clusterversion"
                break
        done
    fi

}

UPDATE_TO_KUBERNETES_VERSION
#TEMP_FOLDER=$(mktemp -d)
#CLUSTERS_FILE_NAME="${TEMP_FOLDER}/${CLUSTERS_FILE_NAME}"
#ERR_LOG_FILE_NAME="${TEMP_FOLDER}/${ERR_LOG_FILE_NAME}"
#EXCLUDED_CLUSTERS_LIST="${EXCLUDED_CLUSTERS_LIST:-}"


function helperCheckScriptRequirements(){
    local __requirements=("az" "jq" "kubectl")

    for __req in ${__requirements[@]}; do
        local __results=$(which $__req)

        if [ $? -eq 0 ]
        then
            echo "SUCCESS Requirement: $__req found."
        else
            echo "FAILED Requirement: $__req not found.  Please install '$__req'." > err.log
            return 1
        fi
    done
}

# Function for comparing versions.
function helperCheckSemVer() {
    echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4) }'
}

export UPDATE_TO_KUBERNETES_VERSION="$clusterversion"
# Function clear previous files
function helperClearTempFiles() {
    rm -rf $TEMP_FOLDER
    mkdir -p $TEMP_FOLDER
}


function upgradeNodePoolsInCluster() {
    local __clusterName=$kubenetes_name
    local __RG=$resourcegroup
    for __nodePoolName in $(az aks nodepool list --cluster-name $__clusterName --resource-group $__RG --query "[].name" -o tsv); do
        echo "Upgrading node pool $__nodePoolName in cluster $__clusterName"
        az aks nodepool upgrade --cluster-name $__clusterName --resource-group $__RG --name $__nodePoolName --kubernetes-version $UPDATE_TO_KUBERNETES_VERSION 
    done

}

function upgradeNodePool() {
    local __RG=$1
    local __clusterName=$2
    local __oldNodePoolName=$3
    local __suffix="v${UPDATE_TO_KUBERNETES_VERSION//./}"
    local __arr=($(echo $__oldNodePoolName | tr "v" " "))
    local __newNodePoolName="${__arr[@]:0:1}$__suffix"
    local __nodePoolCount=$(cat "$TEMP_FOLDER$CLUSTERS_FILE_NAME" | jq -r --arg clusterName "$__clusterName" --arg nodePoolName "$__oldNodePoolName" '.[] | select(.name==$clusterName).agentPoolProfiles[] | select(.name==$nodePoolName).count')
    local __nodePoolVMSize=$(cat "$TEMP_FOLDER$CLUSTERS_FILE_NAME" | jq -r --arg clusterName "$__clusterName" --arg nodePoolName "$__oldNodePoolName" '.[] | select(.name==$clusterName).agentPoolProfiles[] | select(.name==$nodePoolName).vmSize')

    # checkNodePoolNameisValid $__RG $__clusterName $__newNodePoolName
    echo "$createListOfNodesInNodePool => $__oldNodePoolName"
    echo
    createListOfNodesInNodePool $__oldNodePoolName
    echo
    echo "Creating new node pool $__newNodePoolName in cluster $__clusterName, with $__nodePoolCount nodes of size $__nodePoolVMSize"
    echo
    echo
    createNewNodePool $__RG $__clusterName $__newNodePoolName $__nodePoolCount $__nodePoolVMSize
    
    if [ $? -eq 0 ]
    then
        echo "Successfully created new node pool $__newNodePoolName in cluster $__clusterName"
        echo
        echo
        echo "Draining nodes in node pool $__oldNodePoolName in cluster $__clusterName"
        tainitAndDrainNodePool $__oldNodePoolName
        echo
        echo
        echo "Deleting node pool $__oldNodePoolName in cluster $__clusterName"

        if [ $? -eq 0 ]
        then
            echo
            deleteNodePool $__RG $__clusterName $__oldNodePoolName
            echo
            echo
            echo "Successfully deleted node pool $__oldNodePoolName in cluster $__clusterName"
        else
            return 0
            echo
        fi
    else
        return 1
        echo

    fi
}

function tainitAndDrainNodePool() {
    echo
    echo "Draining nodes in node pool $1"
    echo
    local __nodePoolName=$1
    echo
    echo "kubectl get nodes --selector=agentpool=$__nodePoolName"
    echo
    taintNodePool $__nodePoolName
    echo
    echo "kubectl get nodes --selector=agentpool=$__nodePoolName"
    if [ $? -eq 0 ]
    then
        echo
        echo
        drainNodePool $__nodePoolName
        echo
        echo
        echo "Successfully drained nodes in node pool $__nodePoolName"
        if [ $? -eq 0 ]
        then
            return 0
            echo
        else 
            return 1
            echo

        fi
    else
        return 1
        echo

    fi
}

function checkNodePoolNameIsValid() {
    echo
    echo "Checking if node pool name $3 is valid"
    local __RG=$1
    local __clusterName=$2
    local __nodePoolName=$3
    # Commented out Reason: az aks nodepool will check length of nodePoolName
    # local __nodePoolNameLength=$(expr length $__nodePoolName)
    echo
    echo "az aks nodepool list --cluster-name $__clusterName --resource-group $__RG --query \"[?name=='$__nodePoolName'].name\" -o tsv" 
    echo

    local __nameLength=$(expr length $__nodePoolName)
    echo "Node pool name length: $__nameLength"
    echo
    
    if [ "$__nameLength" -gt 12 ]
    echo
    echo 
    then
        echo "Name $__nodePoolName Length is greater than 12...try again"
    else 
        echo "Name length is fine"
    fi
    echo 
    echo

    az aks nodepool show -g $__RG --cluster-name $__clusterName -n $__nodePoolName -o json
    echo
    echo
    if [ $? -eq 0 ]
    then
        echo "Node Pool name $__nodePoolName already Exists"
        return 1
    else 
        echo "Node Pool name $__nodePoolName does not Exist"
        return 0
    fi
}
echo
function createListOfNodesInNodePool() {
    echo
    echo "Creating list of nodes in node pool $1"
    echo
    local __nodePoolName=$1
    echo
    echo "kubectl get nodes --selector=agentpool=$__nodePoolName"
    echo
    kubectl get nodes | grep -w -i $__nodePoolName | awk '{print $1}' > $TEMP_FOLDER"nodepool-"$__nodePoolName".txt"
    echo
    echo "cat $TEMP_FOLDER"nodepool-"$__nodePoolName".txt""
    return 0
    echo

}

function createNewNodePool() {
    echo
    echo "Creating new node pool $3 in cluster $2"
    echo
    local __RG=$1
    local __clusterName=$2
    local __newNodePoolName=$3
    local __nodePoolCount=$4
    local __nodePoolVMSize=$5
    echo
    echo "az aks nodepool add --cluster-name $__clusterName --resource-group $__RG --name $__newNodePoolName --node-count $__nodePoolCount --node-vm-size $__nodePoolVMSize --kubernetes-version $UPDATE_TO_KUBERNETES_VERSION"
    echo

    # Create new NodePool for workloads to move too
    echo "Creating new NodePool: $__newNodePoolName"
    
    az aks nodepool add \
        -g $__RG --cluster-name $__clusterName \
        -n $__newNodePoolName \
        -c $__nodePoolCount \
        -s $__nodePoolVMSize

    if [ $? -eq 0 ]
    then
        echo "Success: Created new NodePool: $__newNodePoolName"
        return 0
    else
        echo "Failure: Did Not Create new NodePool: $__newNodePoolName"
        return 1
    fi
}
echo
# Taint Node Pool
function taintNodePool() {
    echo
    echo "Tainting node pool $1"
    echo
    local __nodePoolName=$1
    local __nodesListFile=$TEMP_FOLDER"nodepool-"$__nodePoolName".txt"
    local __taintListFile=$TEMP_FOLDER"nodepool-"$__nodePoolName"-taint.txt"
    echo
    echo "cat $__nodesListFile"
    echo
    # duplicate Node List to Taint List to track progress
    cp $__nodesListFile $__taintListFile
    echo
    echo "cat $__taintListFile"
    echo
    for __nodeName in $(cat $__taintListFile)
    do
        echo "Tainting Node '$__nodeName' in Node Pool '$__nodePoolName'"        
        kubectl taint node $__nodeName GettingUpgraded=:NoSchedule
        # remove node name from list to track progress
        sed -e s/$__nodeName//g -i $__taintListFile
        echo "Done: Node '$__nodeName' in Node Pool '$__nodePoolName' Tainted."
    done

    echo "done - Tainting current Node Pool '$__nodePoolName'"
    mv $__taintListFile "$__taintListFile".done
    echo

}

function untaintNodePool() {
    echo
    echo "Untainting node pool $1"
    echo
    local __nodePoolName=$1
    local __nodesListFile=$TEMP_FOLDER"nodepool-"$__nodePoolName".txt"
    local __untaintListFile=$TEMP_FOLDER"nodepool-"$__nodePoolName"-untaint.txt"
    echo
    echo "cat $__nodesListFile"
    echo
    # duplicate Node List to Taint List to track progress
    cp $__nodesListFile $__untaintListFile

    for __nodeName in $(cat $__untaintListFile)
    do
        echo "Untainting Node '$__nodeName' in Node Pool '$__nodePoolName'"
        kubectl taint node $__nodeName GettingUpgraded=:NoSchedule-
        # remove node name from list to track progress
        sed -e s/$__nodeName//g -i $__untaintListFile
        echo "Done: Node '$__nodeName' in Node Pool '$__nodePoolName' Untainted."
    done
    echo 
    echo "done - Untainting current Node Pool '$__nodePoolName'"
    mv $__untaintListFile "$__untaintListFile".done
    echo

}

function drainNodePool() {
    echo
    echo "Draining node pool $1"
    echo
    local __nodePoolName=$1
    local __nodesListFile=$TEMP_FOLDER"nodepool-"$__nodePoolName".txt"
    local __drainListFile=$TEMP_FOLDER"nodepool-"$__nodePoolName"-drain.txt"
    echo
    echo "cat $__nodesListFile"
    echo
    
    # duplicate Node List to Taint List to track progress
    cp $__nodesListFile $__drainListFile

    for __nodeName in $(cat $__drainListFile)
    do
        echo "Draining Node '$__nodeName' in Node Pool '$__nodePoolName'"
        kubectl drain $__nodeName --ignore-daemonsets --delete-local-data
        
        if [ $? -eq 0 ]
        then
            sleep 60
            # remove node name from list to track progress
            sed -e s/$__nodeName//g -i $__drainListFile
            echo "Done: Node '$__nodeName' in Node Pool '$__nodePoolName' Drained."
        else
            echo "Failure: Node '$__nodeName' in Node Pool '$__nodePoolName' **NOT** Drained."
            return 1
        fi
    done

    echo "done - Draining current Node Pool '$__nodePoolName'"
    mv $__drainListFile "$__drainListFile".done
    echo

}

function deleteNodePool() {
    echo
    echo "Deleting node pool $1"
    echo
    local __RG=$1
    local __clusterName=$2
    local __nodePoolName=$3
    echo

    # Delete current NodePool
    echo "Deleting NodePool $__nodePoolName"
    
    az aks nodepool delete \
        -g $__RG \
        --cluster-name $__clusterName \
        -n $__nodePoolName

    if [ $? -eq 0 ]
    then
        echo "Success: Deleted Node Pool: $__nodePoolName"
        return 0
    else
        echo "Failure: Unable to delete Node Pool: $__nodePoolName" >> $TEMP_FOLDER$ERR_LOG_FILE_NAME
        return 1
    fi
}
echo

### Cluster functions
function createClusterUpgradeCandidatesJSON(){
    echo "Generating list of AKS CLusters to upgrade..."
    local __candidatesSummaryDetails=$(az aks list --query "[].{name: name, id: id, kubernetesVersion: kubernetesVersion, resourceGroup: resourceGroup, agentPoolProfiles: agentPoolProfiles[?orchestratorVersion < '$UPDATE_TO_KUBERNETES_VERSION' && osType == 'Linux' && mode == 'User'].{count:count, name: name, mode: mode, vmSize: vmSize, orchestratorVersion:orchestratorVersion}}" -o json)
    echo $__candidatesSummaryDetails > "$TEMP_FOLDER/$CLUSTERS_FILE_NAME"

    if [ $? -eq 0 ]
    then
        echo "Succeeded to create list of cluster upgrade candidates"
        removeClustersFromUpgradeCandidatesJSON
        
        if [ $? -eq 0 ]
        then
            return 0
        else 
            return 1
        fi
    else
        echo "Failed to create list of cluster upgrade candidates" >> $TEMP_FOLDER$ERR_LOG_FILE_NAME
        return 1
    fi
}

function removeClustersFromUpgradeCandidatesJSON() {
    echo
    
    local __excludedClusterArray=""
    local __clustersFileJSON="$TEMP_FOLDER$CLUSTERS_FILE_NAME"

    if [ -z "$__excludedClusterArray" ]
    then
        echo "No clusters remove from list of cluster upgrade candidates"
        return 0
    else
        echo "Removing clusters: $__excludedClusterArray"
        echo "fails here"
        for __excludedCluster in "${__excludedClusterArray[@]}"
        do
            echo "fails here2"
            local __arr=($(echo $__excludedCluster | tr ":" " "))

            # Using messey array syntax to make array indexes consistent between bash & ZSH
            local __RG="${__arr[@]:0:1}"
            local __clusterName="${__arr[@]:1:1}"

            removeClusterFromClusterUpgradeCandidatesJSON $__RG $__clusterName
        done
    fi
}

function removeClusterFromClusterUpgradeCandidatesJSON() {
    local __RG=$1
    local __clusterName=$1

    cp "$TEMP_FOLDER$CLUSTERS_FILE_NAME" "$TEMP_FOLDER$CLUSTERS_FILE_NAME.original.backup"
    echo "fails here3"
    cat "$TEMP_FOLDER$CLUSTERS_FILE_NAME.original.backup" \
        | jq -r --arg RG "$__RG" --arg clusterName "$__clusterName" '[.[] | select((.name!=$RG) and (.resourceGroup!=$clusterName))]' \
        > "$TEMP_FOLDER$CLUSTERS_FILE_NAME.new"
}

function checkClusterExists() {
    local __RG=$1
    local __clusterName=$2
    
    if [ "$(az aks show -g $__RG -n $__clusterName -o tsv --query 'name')" = "$__clusterName" ]
    then
        echo "Cluster Found"

        cluster_version=$(az aks show -g $RG -n $NAME -o tsv --query 'kubernetesVersion')
        return 0
    else
        echo "Cluster Not Found"
        return 1
    fi
}

function checkAndUpgradeAllClusterControlPlanes() {
    echo
    
    checkAllClusterControlPlanes 0
}

function checkAllClusterControlPlanes() {
    local __upgradeControlPlane="${1:-1}"

    for __clusterName in $(cat "$TEMP_FOLDER$CLUSTERS_FILE_NAME" | jq -r '.[] | .name')    
    do
        local __RG=$(cat "$TEMP_FOLDER$CLUSTERS_FILE_NAME" | jq -r --arg clusterName "$__clusterName" '.[] | select(.name==$clusterName).resourceGroup')
        local __clusterK8sVersion=$(cat "$TEMP_FOLDER$CLUSTERS_FILE_NAME" | jq -r --arg clusterName "$__clusterName" '.[] | select(.name==$clusterName).kubernetesVersion')
        local __targetK8sVersion=$UPDATE_TO_KUBERNETES_VERSION
        
        checkClusterControlPlane $__RG $__clusterName $__clusterK8sVersion $__targetK8sVersion $__upgradeControlPlane
    done
}

function checkAndUpgradeClusterControlPlane() {
    local __RG=$resourcegroup
    local __clusterName=$kubenetes_name
    local __clusterK8sVersion=$(az aks show -n $kubenetes_name -g $resourcegroup  --query kubernetesVersion -o tsv)
    local __targetK8sVersion=$clusterversion

    checkClusterControlPlane $__RG $__clusterName $__clusterK8sVersion $__targetK8sVersion 0
}

function checkClusterControlPlane() {
    local __RG=$1
    local __clusterName=$2
    local __clusterK8sVersion=$3
    local __targetK8sVersion=$4
    local __upgradeControlPlane="${5:-1}"

    checkClusterControlPlaneNeedsUpgrade $__RG $__clusterName $__clusterK8sVersion $__targetK8sVersion $__upgradeControlPlane
}

function checkClusterControlPlaneNeedsUpgrade() {
    echo
    echo "Checking Cluster Control Plane: $__clusterName"
    echo
    local __RG=$1
    local __clusterName=$2
    local __clusterK8sVersion=$3
    local __targetK8sVersion=$4
    local __upgradeControlPlane="${5:-1}"
    echo 

    if [ $(helperCheckSemVer $__clusterK8sVersion) -lt $(helperCheckSemVer $__targetK8sVersion) ]
    then
        echo "Control Plane Upgrade needed for cluster $__clusterName."
        echo "Current Cluster version equal to: $__clusterK8sVersion"
        echo "Target Cluster version K8s $__targetK8sVersion"
        
        if [ "$__upgradeControlPlane" -eq 0 ]
        echo
        echo "Upgrade Control Plane: $__clusterName"
        echo
        then
            echo 
            upgradeClusterControlPlane $__RG $__clusterName $__targetK8sVersion
            echo
            if [ $? -eq 0 ]
            then
                return 0
            else 
                return 1
            fi
        fi
    else 
        echo "Control Plane Upgrade not needed."
        echo "Control Plane version equal to: $__clusterK8sVersion."
        echo "Target K8s $__targetK8sVersion"

        return 1
    fi
}

function upgradeClusterControlPlane() {
    echo
    echo "Upgrading Cluster Control Plane: $__clusterName"
    echo
    local __RG=$1
    local __clusterName=$2
    local __K8SVersion=$3
    echo
    echo "Upgrading Cluster $__clusterName Control Plane to K8s v.$__K8SVersion"
    echo "Started at: $(date)"
    
    ## Problem: Bug in CLI where -y/--yes flag is ignored and user input is still required.
    # az aks upgrade -g $__RG -n $__clusterName -k $__K8SVersion --control-plane-only --yes

    ## Work around for above Problem
    echo
    local __resourceID=$(cat "$TEMP_FOLDER$CLUSTERS_FILE_NAME" | jq -r --arg RG "$__RG" --arg clusterName "$__clusterName" '.[] | select((.name==$clusterName) and (.resourceGroup==$RG)).id')
    az resource update --ids $__resourceID --set "properties.kubernetesVersion=$__K8SVersion"


    if [ $? -eq 0 ]
    then
        echo
        echo "Succeeded: Upgraded Cluster $__clusterName Control Plane to K8s v.$__K8SVersion"
        echo "Finished at: $(date)"
        return 0
    else 
        echo "Failed: Control Plane Upgrade to v.$__K8SVersion"
        return 1
    fi
    
}

function checkAndRollingUpgradeAllClustersAndNodePools() {
    echo
    echo "Checking and Rolling Upgrading All Clusters and Node Pools"
    echo
    for __clusterName in $(cat "$TEMP_FOLDER$CLUSTERS_FILE_NAME" | jq -r '.[] | .name')
    do
        local __RG=$(cat "$TEMP_FOLDER$CLUSTERS_FILE_NAME"| jq -r --arg clusterName "$__clusterName" '.[] | select(.name==$clusterName).resourceGroup')
        local __clusterK8sVersion=$(cat "$TEMP_FOLDER$CLUSTERS_FILE_NAME"| jq -r --arg clusterName "$__clusterName" '.[] | select(.name==$clusterName).kubernetesVersion')
        local __targetK8sVersion=$UPDATE_TO_KUBERNETES_VERSION
        echo
        echo "Checking and Rolling Upgrading Cluster: $__clusterName"
        getClusterCredentials $__RG $__clusterName
        setClusterConfigContext $__clusterName
        checkAndUpgradeClusterControlPlane $__RG $__clusterName $__clusterK8sVersion $__targetK8sVersion
        echo
        echo "Checking and Rolling Upgrading Node Pools for Cluster: $__clusterName"
        if [ $? -eq 0 ]
        then
            echo
            upgradeNodePoolsInCluster $__clusterName
            echo
            echo "Finished Rolling Upgrading Node Pools for Cluster: $__clusterName"
            if [ $? -eq 0 ]
            then
                echo
                echo "Successfully upgraded Cluster: $__clusterName"
                echo
            else
                echo
                echo "Failed to upgrade Cluster: $__clusterName"
                echo
            fi
        fi
    done
}

function getClusterCredentials() {
    echo
    echo "Getting Cluster Credentials: $__clusterName"
    echo
    local __RG=$1
    local __clusterName=$2
    echo

    # Get Kube Config Creds and overwrite if already exists (No User Prompts)
    az aks get-credentials -g $__RG -n $__clusterName --overwrite-existing
}

function setClusterConfigContext() {
    echo
    echo "Setting Cluster Config Context: $__clusterName"
    echo
    local __clusterName=$1
    echo
    kubectl config set-context $__clusterName
}


function main() {
    echo
    echo "Starting AKS Cluster and Node Pool Upgrade Script"
    echo
    helperCheckScriptRequirements
    echo
    echo "Getting AKS Clusters"
    echo
    helperClearTempFiles
    echo
    createClusterUpgradeCandidatesJSON
    echo
    checkAndRollingUpgradeAllClustersAndNodePools
}


main