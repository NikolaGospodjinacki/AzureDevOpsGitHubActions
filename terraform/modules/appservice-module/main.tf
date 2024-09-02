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

variable "appservice_sku_name" {
  type = string
}

variable "appservice_docker_image_and_tag" {
  type = string
}

variable "appservice_docker_registry_server_url" {
  type = string
}

variable "cosmos_prim_connection_string" {
  type = string
}

variable "cosmos_sec_connection_string" {
  type = string
}

variable "int_api_subnet_id" {
  type = string
}

variable "api_subnet_id" {
  type = string
}

variable "api_private_dns_zone_name" {
  type = string
}

variable "api_private_dns_zone_id" {
  type = string
}
#############################################################################
#############################################################################

resource "azurerm_service_plan" "appplan-proto-weu-01" {
  name                = "appplan-${var.project}-${var.environment}-${var.region}-01"
  resource_group_name = var.resource_group
  location            = var.region
  os_type             = "Linux"
  sku_name            = var.appservice_sku_name
}

resource "azurerm_linux_web_app" "app-proto-weu-01" {
  name                = "app-${var.project}-${var.environment}-${var.region}-01"
  resource_group_name = var.resource_group
  location            = var.region
  service_plan_id     = azurerm_service_plan.appplan-proto-weu-01.id
  https_only          = true

  site_config {
    always_on = true

    application_stack {
      docker_image_name = var.appservice_docker_image_and_tag
    }
  }

  app_settings = {
    DOCKER_ENABLE_CI                   = true
    DOCKER_REGISTRY_SERVER_URL         = var.appservice_docker_registry_server_url
    COSMOS_PRIMARY_CONNECTION_STRING   = var.cosmos_prim_connection_string
    COSMOS_SECONDARY_CONNECTION_STRING = var.cosmos_sec_connection_string
    WEBSITES_PORT                      = 5000
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "appswift-proto-weu-01" {
  app_service_id = azurerm_linux_web_app.app-proto-weu-01.id
  subnet_id      = var.int_api_subnet_id
}

#Private endpoint
resource "azurerm_private_endpoint" "pe-proto-api-weu-01" {
  name                = "pe-${var.project}-api-${var.environment}-${var.region}-01"
  location            = var.region
  resource_group_name = var.resource_group
  subnet_id           = var.api_subnet_id


  private_dns_zone_group {
    name = var.api_private_dns_zone_name
    private_dns_zone_ids = [
      var.api_private_dns_zone_id
    ]
  }

  private_service_connection {
    name                           = "peconn-${var.project}-api-${var.environment}-${var.region}-01"
    private_connection_resource_id = azurerm_linux_web_app.app-proto-weu-01.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_a_record" "dnsa-proto-api-weu-01" {
  name                = "dnsa-${var.project}-api-${var.environment}-${var.region}-01"
  zone_name           = var.api_private_dns_zone_name
  resource_group_name = var.resource_group
  ttl                 = 300
  records             = [azurerm_private_endpoint.pe-proto-api-weu-01.private_service_connection.0.private_ip_address]
}

#############################################################################
#############################################################################

output "api_app_id" {
  value = azurerm_linux_web_app.app-proto-weu-01.id
}
