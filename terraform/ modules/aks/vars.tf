variable "list_aks" {
  description = "Listagem de clusters"
  type = list(object({
    name                 = list(string)
    resource_group_name  = string
    subnet_name          = string
    virtual_network_name = string
    subnet_rg            = string
    vnet_rg              = string
    dns_prefix           = string
    kubernetes_version   = string
    labels_metrics       = map(any)
    labels_ingress       = map(any)
    labels_workload      = map(any)
    tags                 = map(any)
    ssh_public_key       = string
    os_sku               = string
    client_id            = string
    size_32_64           = string
    size_8_16            = string
  }))
  default = []
}
