locals {
  resource_group_list = {
    for idx, resource_group in var.resource_group :
    "${resource_group.tags[0].ambiente}-${idx}" => resource_group
  }
}