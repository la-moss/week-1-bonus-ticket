locals {
  rg_primary_name   = "${var.project}-rg-${var.env}-pri"
  rg_secondary_name = "${var.project}-rg-${var.env}-dr"

  tags_common = merge(var.tags, {
    env     = var.env
    project = var.project
  })

  tags_alt = {
    env     = var.env
    project = var.project
    cost    = try(var.tags["cost"], "1001")
  }

  hub_primary_name   = "${var.project}-vnet-hub-${var.env}-pri"
  hub_secondary_name = "${var.project}-vnet-hub-${var.env}-dr"

  spoke_primary_name   = "${var.project}-vnet-spoke-${var.env}-pri"
  spoke_secondary_name = "${var.project}-vnet-spoke-${var.env}-dr"

  tm_profile_name = "${var.project}-tm-${var.env}"
}
