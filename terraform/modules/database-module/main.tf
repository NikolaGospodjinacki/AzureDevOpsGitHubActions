variable "project" {
  type = string
}
variable "region" {
  type = string
}

variable "failover_region" {
  type = string
}

variable "environment" {
  type = string
}

variable "resource_group" {
  type = string
}

variable "cosmos_enable_free_tier" {
  type = bool
}

variable "api_subnet_id" {
  type = string
}

variable "cosmos_subnet_id" {
  type = string
}

variable "cosmos_private_dns_zone_id" {
  type = string
}

variable "cosmos_private_dns_zone_name" {
  type = string
}
#############################################################################
#############################################################################

# Database
resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_cosmosdb_account" "cosmos-proto-weu-01" {
  name                 = "cosmos-${var.project}-${var.environment}-${var.region}-01"
  location             = var.region
  resource_group_name  = var.resource_group
  offer_type           = "Standard"
  kind                 = "MongoDB"
  mongo_server_version = "4.0"

  public_network_access_enabled     = false
  is_virtual_network_filter_enabled = true
  network_acl_bypass_ids            = []

  enable_free_tier = var.cosmos_enable_free_tier

  capabilities {
    name = "EnableMongo"
  }

  capabilities {
    name = "EnableServerless"
  }

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.region
    failover_priority = 1
  }

  geo_location {
    location          = var.failover_region
    failover_priority = 0
  }

  virtual_network_rule {
    id = var.api_subnet_id
  }

  virtual_network_rule {
    id = var.cosmos_subnet_id
  }
  #Migration of Periodic to Continuous is one-way, changing Continuous to Periodic forces a new resource to be created.
  backup {
    type = "Periodic"
  }

}

resource "azurerm_cosmosdb_mongo_database" "cosmosdb-proto-weu-01" {
  name                = "cosmosdb-${var.project}-${var.environment}-${var.region}-01"
  resource_group_name = var.resource_group
  account_name        = azurerm_cosmosdb_account.cosmos-proto-weu-01.name
}

resource "azurerm_cosmosdb_mongo_collection" "employees" {
  name                = "employees"
  resource_group_name = azurerm_cosmosdb_account.cosmos-proto-weu-01.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmos-proto-weu-01.name
  database_name       = azurerm_cosmosdb_mongo_database.cosmosdb-proto-weu-01.name

  shard_key = "name"

  index {
    keys = [
      "_id"
    ]

    unique = true
  }

}

#Private endpoint
resource "azurerm_private_endpoint" "pe-proto-cosmos-weu-01" {
  name                = "pe-${var.project}-cosmos-${var.environment}-${var.region}-01"
  location            = var.region
  resource_group_name = var.resource_group
  subnet_id           = var.cosmos_subnet_id

  private_dns_zone_group {
    name = var.cosmos_private_dns_zone_name
    private_dns_zone_ids = [
      var.cosmos_private_dns_zone_id
    ]
  }

  private_service_connection {
    name                           = "peconn-${var.project}-cosmos-${var.environment}-${var.region}-01"
    private_connection_resource_id = azurerm_cosmosdb_account.cosmos-proto-weu-01.id
    subresource_names              = ["MongoDB"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_a_record" "dnsa-proto-cosmos-weu-01" {
  name                = "dnsa-${var.project}-cosmos-${var.environment}-${var.region}-01"
  zone_name           = var.cosmos_private_dns_zone_name
  resource_group_name = var.resource_group
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-proto-cosmos-weu-01.private_service_connection.0.private_ip_address]
}

#############################################################################
#############################################################################

output "cosmos_prim_connection_string" {
  value     = azurerm_cosmosdb_account.cosmos-proto-weu-01.primary_key
  sensitive = true
}

output "cosmos_sec_connection_string" {
  value     = azurerm_cosmosdb_account.cosmos-proto-weu-01.secondary_key
  sensitive = true
}