variable "project" {
  type = string
}
variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "resource_group" {
  type = string
}

variable "storage_subnet_id" {
  type = string
}

variable "storage_private_dns_zone_id" {
  type = string
}

variable "storage_private_dns_zone_name" {
  type = string
}

#############################################################################
#############################################################################

resource "azurerm_storage_account" "st-proto-weu-01" {
  name                       = "st${var.project}${var.environment}${var.region}01"
  resource_group_name        = var.resource_group
  location                   = var.region
  account_tier               = "Standard"
  account_replication_type   = "LRS"
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  network_rules {
    default_action = "Deny"
    ip_rules       = []
  }

}


resource "azurerm_private_endpoint" "pe-proto-st-weu-01" {
  name                = "pe-${var.project}-st-${var.environment}-${var.region}-01"
  resource_group_name = var.resource_group
  location            = var.region
  subnet_id           = var.storage_subnet_id

  private_dns_zone_group {
    name = var.storage_private_dns_zone_name
    private_dns_zone_ids = [
      var.storage_private_dns_zone_id
    ]
  }

  private_service_connection {
    name                           = "peconn-${var.project}-st-${var.environment}-${var.region}-01"
    private_connection_resource_id = azurerm_storage_account.st-proto-weu-01.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_a_record" "dnsa-proto-st-weu-01" {
  name                = "dnsa-${var.project}-st-${var.environment}-${var.region}-01"
  zone_name           = var.storage_private_dns_zone_name
  resource_group_name = var.resource_group
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-proto-st-weu-01.private_service_connection.0.private_ip_address]
}