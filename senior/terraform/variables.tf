variable "project" {
  type        = string
  default     = "atlas"
  description = "Project name prefix."
}

variable "env" {
  type        = string
  default     = "prod"
  description = "Environment name."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription id."
}

variable "primary_location" {
  type        = string
  default     = "uksouth"
  description = "Primary region."
}

variable "secondary_location" {
  type        = string
  default     = "westeurope"
  description = "Secondary region."
}

variable "address_space_primary" {
  type    = list(string)
  default = ["10.40.0.0/16"]
}

variable "address_space_secondary" {
  type    = list(string)
  default = ["10.50.0.0/16"]
}

variable "hub_subnets" {
  type = map(string)
  default = {
    "AzureFirewallSubnet" = "10.40.0.0/24"
    "shared"             = "10.40.1.0/24"
  }
  description = "Hub subnet CIDRs (applied per region with region-specific base)."
}

variable "spoke_subnets" {
  type = map(string)
  default = {
    "app" = "10.40.10.0/24"
  }
  description = "Spoke subnet CIDRs (applied per region with region-specific base)."
}

variable "tags" {
  type = map(string)
  default = {
    owner   = "payments"
    env     = "prod"
    project = "atlas"
    cost    = "1001"
  }
  description = "Standard tags."
}
