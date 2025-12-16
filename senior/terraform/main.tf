module "rg_primary" {
  source    = "./modules/resource_group"
  providers = { azurerm = azurerm.primary }

  name     = local.rg_primary_name
  location = var.primary_location
  tags     = local.tags_common
}

module "rg_secondary" {
  source    = "./modules/resource_group"
  providers = { azurerm = azurerm.secondary }

  name     = local.rg_secondary_name
  location = var.secondary_location
  tags     = local.tags_common
}

module "hub_primary" {
  source    = "./modules/network"
  providers = { azurerm = azurerm.primary }

  resource_group_name = module.rg_primary.name
  location            = var.primary_location
  name                = local.hub_primary_name
  address_space       = var.address_space_primary
  subnets             = var.hub_subnets
  tags                = local.tags_common
}

module "hub_secondary" {
  source    = "./modules/network"
  providers = { azurerm = azurerm.secondary }

  resource_group_name = module.rg_secondary.name
  location            = var.secondary_location
  name                = local.hub_secondary_name
  address_space       = var.address_space_secondary
  subnets             = {
    "AzureFirewallSubnet" = "10.50.0.0/24"
    "shared"             = "10.50.1.0/24"
  }
  tags                = local.tags_common
}

module "spoke_primary" {
  source    = "./modules/network"
  providers = { azurerm = azurerm.primary }

  resource_group_name = module.rg_primary.name
  location            = var.primary_location
  name                = local.spoke_primary_name
  address_space       = ["10.41.0.0/16"]
  subnets             = {
    "app" = "10.41.10.0/24"
  }
  tags                = local.tags_common
}

module "spoke_secondary" {
  source    = "./modules/network"
  providers = { azurerm = azurerm.secondary }

  resource_group_name = module.rg_secondary.name
  location            = var.secondary_location
  name                = local.spoke_secondary_name
  address_space       = ["10.51.0.0/16"]
  subnets             = {
    "app" = "10.51.10.0/24"
  }
  tags                = local.tags_common
}

# Regional hub<->spoke peering (per region)
resource "azurerm_virtual_network_peering" "pri_hub_to_spoke" {
  provider                  = azurerm.primary
  name                      = "${var.project}-peer-hub-to-spoke-pri"
  resource_group_name       = module.rg_primary.name
  virtual_network_name      = module.hub_primary.vnet_name
  remote_virtual_network_id = module.spoke_primary.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "pri_spoke_to_hub" {
  provider                  = azurerm.primary
  name                      = "${var.project}-peer-spoke-to-hub-pri"
  resource_group_name       = module.rg_primary.name
  virtual_network_name      = module.spoke_primary.vnet_name
  remote_virtual_network_id = module.hub_primary.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "dr_hub_to_spoke" {
  provider                  = azurerm.secondary
  name                      = "${var.project}-peer-hub-to-spoke-dr"
  resource_group_name       = module.rg_secondary.name
  virtual_network_name      = module.hub_secondary.vnet_name
  remote_virtual_network_id = module.spoke_secondary.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "dr_spoke_to_hub" {
  provider                  = azurerm.secondary
  name                      = "${var.project}-peer-spoke-to-hub-dr"
  resource_group_name       = module.rg_secondary.name
  virtual_network_name      = module.spoke_secondary.vnet_name
  remote_virtual_network_id = module.hub_secondary.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

# Cross-region hub peering (used for operator access patterns and shared services during failover)
resource "azurerm_virtual_network_peering" "pri_hub_to_dr_hub" {
  provider                  = azurerm.primary
  name                      = "${var.project}-peer-hub-pri-to-hub-dr"
  resource_group_name       = module.rg_primary.name
  virtual_network_name      = module.hub_primary.vnet_name
  remote_virtual_network_id = module.hub_secondary.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

# Public entrypoints (one per region)
resource "azurerm_public_ip" "pri_entry" {
  provider            = azurerm.primary
  name                = "${var.project}-pip-entry-pri"
  location            = var.primary_location
  resource_group_name = module.rg_primary.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags_common
}

resource "azurerm_public_ip" "dr_entry" {
  provider            = azurerm.secondary
  name                = "${var.project}-pip-entry-dr"
  location            = var.secondary_location
  resource_group_name = module.rg_secondary.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    env     = var.env
    project = var.project
    cost    = try(var.tags["cost"], "1001")
  }
}

module "traffic_manager" {
  source    = "./modules/traffic_manager"
  providers = { azurerm = azurerm.primary }

  profile_name        = local.tm_profile_name
  resource_group_name = module.rg_primary.name
  tags                = local.tags_common

  primary_target_resource_id   = azurerm_public_ip.pri_entry.id
  secondary_target_resource_id = azurerm_public_ip.dr_entry.id
}

module "storage_primary" {
  source    = "./modules/storage"
  providers = { azurerm = azurerm.primary }

  resource_group_name = module.rg_primary.name
  location            = var.primary_location
  name                = "${var.project}st${replace(var.env, "-", "")}pri"
  tags                = local.tags_common
}

module "storage_secondary" {
  source    = "./modules/storage"
  providers = { azurerm = azurerm.secondary }

  resource_group_name = module.rg_secondary.name
  location            = var.secondary_location
  name                = "${var.project}st${replace(var.env, "-", "")}dr"
  tags                = local.tags_common
}
