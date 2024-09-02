variable "project" {
  type = string
}
variable "region" {
  type = string
}

variable "resource_group" {
  type = string
}

variable "environment" {
  type = string
}

variable "redis_subnet_id" {
  type = string
}

variable "redis_plan_sku_name" {
  type = string
}

variable "redis_plan_capacity" {
  type = string
}

variable "redis_plan_family" {
  type = string
}

variable "redis_private_dns_zone_id" {
  type = string
}

variable "redis_private_dns_zone_name" {
  type = string
}

#############################################################################
#############################################################################

resource "azurerm_redis_cache" "redis-proto-redis-weu-01" {
  name                          = "redis-${var.project}-${var.environment}-${var.region}-01"
  location                      = var.region
  resource_group_name           = var.resource_group
  sku_name                      = var.redis_plan_sku_name
  capacity                      = var.redis_plan_capacity
  family                        = var.redis_plan_family
  non_ssl_port_enabled          = false
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false
}


#Private endpoint
resource "azurerm_private_endpoint" "pe-proto-redis-weu-01" {
  name                = "pe-${var.project}-redis-${var.environment}-${var.region}-01"
  location            = var.region
  resource_group_name = var.resource_group
  subnet_id           = var.redis_subnet_id

  private_dns_zone_group {
    name = var.redis_private_dns_zone_name
    private_dns_zone_ids = [
      var.redis_private_dns_zone_id
    ]
  }

  private_service_connection {
    name                           = "peconn-${var.project}-redis-${var.environment}-${var.region}-01"
    private_connection_resource_id = azurerm_redis_cache.redis-proto-redis-weu-01.id
    subresource_names              = ["redisCache"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_a_record" "dnsa-proto-redis-weu-01" {
  name                = "dnsa-${var.project}-redis-${var.environment}-${var.region}-01"
  zone_name           = var.redis_private_dns_zone_name
  resource_group_name = var.resource_group
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-proto-redis-weu-01.private_service_connection.0.private_ip_address]
}