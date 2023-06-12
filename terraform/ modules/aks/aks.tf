# data "azurerm_virtual_network" "aks_env_vnet" {
#   count               = length(var.list_aks)
#   name                = var.list_aks[count.index].virtual_network_name
#   resource_group_name = var.list_aks[count.index].vnet_rg
# }

data "azurerm_virtual_network" "aks_env_vnet" {
  for_each = local.list_aks ? 1 : 0 # esse if é para não dar erro quando não tiver aks
  name                = each.value.virtual_network_name
  resource_group_name = each.value.vnet_rg
}

locals {
  list_aks = {
    for idx, value in var.list_aks :
    value.name[0] => value
  }
}

data "azurerm_subnet" "aks_env_subnet" {
  for_each = local.list_aks ? 1 : 0 # esse if é para não dar erro quando não tiver aks
  name                 = each.value.subnet_name
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = each.value.subnet_rg
}

# data "azurerm_subnet" "aks_env_subnet" {
#   count                = length(var.list_aks)
#   name                 = var.list_aks[count.index].subnet_name
#   virtual_network_name = var.list_aks[count.index].virtual_network_name
#   resource_group_name  = var.list_aks[count.index].subnet_rg
# }

# resource "azurerm_resource_group" "aks_env_rg" {
#   count    = length(var.list_rg)
#   name     = var.list_rg[count.index].name
#   location = var.region
#   tags     = var.list_rg[count.index].tags
# }

resource "azurerm_kubernetes_cluster" "aks_env_cluster" {
  for_each = local.list_aks 

  name                                = each.value.name[0]
  location                            = each.value.location
  resource_group_name                 = each.value.resource_group_name[0]
  dns_prefix                          = each.value.dns_prefix[0]
  private_cluster_enabled             = each.value.private_cluster ? true : false
  private_cluster_public_fqdn_enabled = each.value.private_cluster_public_fqdn ? true : false
  kubernetes_version                  = each.value.kubernetes_version ? each.value.kubernetes_version : null
  tags                                = each.value.tags ? each.value.tags : null
  #depends_on                          = [azurerm_resource_group.aks_env_rg]
  default_node_pool {
    name           = "workload"
    node_count     = 1
    vm_size        = each.value.size_32_64
    os_sku         = each.value.os-sku
    node_labels    = each.value.labels_workload
    vnet_subnet_id = data.azurerm_subnet.aks_env_subnet[each.key].id
    tags           = each.value.tags
  }
  linux_profile {
    admin_username = each.value.linux_profile.admin_username
    ssh_key {
      key_data = file(each.value.ssh_public_key)
    }
  }

  network_profile {
    network_plugin    = each.value.network_profile.network_plugin
    load_balancer_sku = each.value.network_profile.load_balancer_sku
  }

  service_principal {
    client_id     = each.value.client_id
    client_secret = each.value.client_secret
  }

}


# resource "azurerm_kubernetes_cluster" "aks_env_cluster" {
#   count                               = length(var.list_aks)
#   name                                = var.list_aks[count.index].name
#   location                            = var.region
#   resource_group_name                 = var.list_aks[count.index].resource_group_name
#   dns_prefix                          = var.list_aks[count.index].dns_prefix
#   private_cluster_enabled             = true
#   private_cluster_public_fqdn_enabled = true
#   kubernetes_version                  = var.list_aks[count.index].kubernetes_version
#   tags                                = var.list_aks[count.index].tags
#   depends_on                          = [azurerm_resource_group.aks_env_rg]

#   default_node_pool {
#     name           = "workload"
#     node_count     = 1
#     vm_size        = var.size_32_64
#     os_sku         = var.os-sku
#     node_labels    = var.list_aks[count.index].labels_workload
#     vnet_subnet_id = data.azurerm_subnet.aks_env_subnet[count.index].id
#     tags           = var.list_aks[count.index].tags
#   }

#   linux_profile {
#     admin_username = "ubuntu"

#     ssh_key {
#       key_data = file(var.ssh_public_key)
#     }
#   }

#   network_profile {
#     network_plugin    = "kubenet"
#     load_balancer_sku = "standard"
#   }

#   service_principal {
#     client_id     = var.client_id
#     client_secret = var.client_secret
#   }
# }

# resource "azurerm_kubernetes_cluster_node_pool" "ingress" {
#   count                 = length(var.list_aks)
#   name                  = "ingress"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_env_cluster[count.index].id
#   vm_size               = var.size_8_16
#   os_sku                = var.os-sku
#   node_taints           = ["node.k8s.bb/servico=nginx-ingress:NoSchedule"]
#   node_labels           = var.list_aks[count.index].labels_ingress
#   node_count            = 2
#   vnet_subnet_id        = data.azurerm_subnet.aks_env_subnet[count.index].id
#   mode                  = "User"
#   tags                  = var.list_aks[count.index].tags

# }


# resource "azurerm_kubernetes_cluster_node_pool" "metrics" {
#   count                 = length(var.list_aks)
#   name                  = "metrics"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_env_cluster[count.index].id
#   vm_size               = var.size_32_64
#   os_sku                = var.os-sku
#   node_taints           = ["node.k8s.bb/servico=metrics:NoSchedule"]
#   node_labels           = var.list_aks[count.index].labels_metrics
#   node_count            = 1
#   vnet_subnet_id        = data.azurerm_subnet.aks_env_subnet[count.index].id
#   mode                  = "User"
#   tags                  = var.list_aks[count.index].tags

# }

