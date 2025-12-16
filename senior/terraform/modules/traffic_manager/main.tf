resource "azurerm_traffic_manager_profile" "this" {
  name                   = var.profile_name
  resource_group_name    = var.resource_group_name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = var.profile_name
    ttl           = 30
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/healthz"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 3
  }

  tags = var.tags
}

resource "azurerm_traffic_manager_azure_endpoint" "primary" {
  name               = "pri-endpoint"
  profile_id         = azurerm_traffic_manager_profile.this.id
  weight             = 100
  priority           = 1
  target_resource_id = var.primary_target_resource_id
}
