resource "azurerm_resource_group" "rg-dev-euw-01" {
    location = var.region
    name     = "rg-${var.project}-${var.environment}-${var.region}-01"
}

