provider "azurerm" {
  features {}
  alias           = "primary"
  subscription_id = var.subscription_id
}

provider "azurerm" {
  features {}
  alias           = "secondary"
  subscription_id = var.subscription_id
}
