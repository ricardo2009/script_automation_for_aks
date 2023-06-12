output "name" {
  value = [for rg in azurerm_resource_group.rg : rg.name]
}

output "location" {
  value = [for rg in azurerm_resource_group.rg : rg.location]
}

output "id" {
  value = [for rg in azurerm_resource_group.rg : rg.id]
}

output "tags" {
  value = [for rg in azurerm_resource_group.rg : rg.tags]
}
