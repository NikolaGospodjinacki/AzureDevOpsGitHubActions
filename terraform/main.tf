variable "project" {
  type        = string
  default     = "proto"
  description = "Your project name"
}

variable "region" {
  type        = string
  default     = "westeurope"
  description = "Azure region where the resources are going to be deployed"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Deployment environment"
}


#Database(MongoDB variables)
variable "failover_region" {
  type        = string
  default     = "northeurope"
  description = "failover region 2 for cosmosDB"
}

variable "cosmos_enable_free_tier" {
  type    = bool
  default = true
}


#App service variables
variable "appservice_sku_name" {
  type    = string
  default = "S1"
}

variable "appservice_docker_registry_server_url" {
  description = "The URL of the docker registry"
  type        = string
  default     = "https://index.docker.io"
}

variable "appservice_docker_image_and_tag" {
  type        = string
  default     = "epomatti/big-azure-terraform-showcase:latest"
  description = "free docker image being pulled to showcase the project"
  #Change to version number from 'latest' for production use cases
}

#Redis cache variables
variable "redis_plan_sku_name" {
  type        = string
  default     = "Basic"
  description = "free docker image being pulled to showcase the project"
}
#Downgrading the SKU will force a new resource to be created.
variable "redis_plan_family" {
  type        = string
  default     = "C"
  description = "free docker image being pulled to showcase the project"
}

variable "redis_plan_capacity" {
  type        = string
  default     = "0"
  description = "free docker image being pulled to showcase the project"
}
#############################################################################
#############################################################################

resource "azurerm_resource_group" "rg-proto-weu-01" {
  location = var.region
  name     = "rg-${var.project}-${var.environment}-${var.region}-01"
}

module "networking-module" {
  source         = "./modules/networking-module"
  project        = var.project
  region         = var.region
  environment    = var.environment
  resource_group = azurerm_resource_group.rg-proto-weu-01.name
}


module "database-module" {
  source                       = "./modules/database-module"
  project                      = var.project
  region                       = var.region
  failover_region              = var.failover_region
  environment                  = var.environment
  cosmos_enable_free_tier      = var.cosmos_enable_free_tier
  api_subnet_id                = module.networking-module.int_api_subnet_id
  cosmos_subnet_id             = module.networking-module.cosmos_subnet_id
  cosmos_private_dns_zone_id   = module.networking-module.cosmos_private_dns_zone_id
  cosmos_private_dns_zone_name = module.networking-module.cosmos_private_dns_zone_name
  resource_group               = azurerm_resource_group.rg-proto-weu-01.name
}


module "appservice-module" {
  source                                = "./modules/appservice-module"
  project                               = var.project
  region                                = var.region
  environment                           = var.environment
  appservice_sku_name                   = var.appservice_sku_name
  appservice_docker_registry_server_url = var.appservice_docker_registry_server_url
  appservice_docker_image_and_tag       = var.appservice_docker_image_and_tag
  cosmos_prim_connection_string         = module.database-module.cosmos_prim_connection_string
  cosmos_sec_connection_string          = module.database-module.cosmos_sec_connection_string
  api_subnet_id                         = module.networking-module.api_subnet_id
  int_api_subnet_id                     = module.networking-module.int_api_subnet_id
  api_private_dns_zone_id               = module.networking-module.api_private_dns_zone_id
  api_private_dns_zone_name             = module.networking-module.api_private_dns_zone_name
  resource_group                        = azurerm_resource_group.rg-proto-weu-01.name
}


module "redis-module" {
  source                      = "./modules/redis-module"
  project                     = var.project
  region                      = var.region
  environment                 = var.environment
  redis_subnet_id             = module.networking-module.redis_subnet_id
  redis_plan_sku_name         = var.redis_plan_sku_name
  redis_plan_capacity         = var.redis_plan_capacity
  redis_plan_family           = var.redis_plan_family
  redis_private_dns_zone_id   = module.networking-module.redis_private_dns_zone_id
  redis_private_dns_zone_name = module.networking-module.redis_private_dns_zone_name
  resource_group              = azurerm_resource_group.rg-proto-weu-01.name
}


module "storage-module" {
  source                        = "./modules/storage-module"
  project                       = var.project
  region                        = var.region
  environment                   = var.environment
  storage_subnet_id             = module.networking-module.storage_subnet_id
  storage_private_dns_zone_id   = module.networking-module.storage_private_dns_zone_id
  storage_private_dns_zone_name = module.networking-module.storage_private_dns_zone_name
  resource_group                = azurerm_resource_group.rg-proto-weu-01.name
}


module "loganalytics-module" {
  source         = "./modules/loganalytics-module"
  project        = var.project
  region         = var.region
  environment    = var.environment
  api_app_id     = module.appservice-module.api_app_id
  resource_group = azurerm_resource_group.rg-proto-weu-01.name
}