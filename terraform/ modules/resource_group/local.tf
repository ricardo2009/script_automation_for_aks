locals {
    resource_group_list = {
        for idx, resource_group in var.resource_group :
        "${ambiente.produto.custom_name}" => resource_group 
    }
}