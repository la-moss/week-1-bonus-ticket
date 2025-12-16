output "resource_groups" {
  value = {
    primary   = module.rg_primary.name
    secondary = module.rg_secondary.name
  }
}

output "hub_vnets" {
  value = {
    primary   = module.hub_primary.vnet_id
    secondary = module.hub_secondary.vnet_id
  }
}

output "traffic_manager_profile_id" {
  value = module.traffic_manager.profile_id
}
