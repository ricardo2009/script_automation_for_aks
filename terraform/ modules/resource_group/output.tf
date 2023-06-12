output "name" {
    value = [for rg in azurem_resource_group.rg : rg.name]
}

output "location" {
    value = [for rg in azurem_resource_group.rg : rg.location]
}

output "ambiente" {
    value = [for rg in azurem_resource_group.rg : rg.tags.ambiente]
}

output "custom_name" {
    value = [for rg in azurem_resource_group.rg : rg.tags.custom_name]
}

