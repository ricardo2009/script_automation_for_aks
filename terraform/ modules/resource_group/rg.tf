resource "azurerm_resource_group" {
    for_each = local.resource_group_list

    name= each.value.name[0]
    location = each.value.location 
    tags = var.tags
}