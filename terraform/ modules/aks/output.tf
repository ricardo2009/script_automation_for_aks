output "aks_env_vnet" {
  value = [for rg in azurerm_virtual_network.aks_env_cluster : aks_env_cluster.name]
}

output "aks_env_subnet" {
  value = [for rg in azurerm_subnet.aks_env_subnet : aks_env_subnet.name]
}

output "aks_env_cluster" {
  value = [for rg in azurerm_kubernetes_cluster.aks_env_cluster : aks_env_cluster.name]
}

output "aks_env_cluster_id" {
  value = [for rg in azurerm_kubernetes_cluster.aks_env_cluster : aks_env_cluster.id]
}

