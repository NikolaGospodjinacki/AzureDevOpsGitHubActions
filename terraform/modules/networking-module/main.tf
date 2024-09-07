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

#############################################################################
#############################################################################

# Networking
resource "azurerm_virtual_network" "vnet-proto-neu-01" {
  name                = "vnet-${var.project}-${var.environment}-${var.region}-01"
  location            = var.region
  resource_group_name = var.resource_group
  address_space       = ["10.100.10.0/24"]


}

resource "azurerm_subnet" "snet-proto-int-api-neu-01" {
  name                              = "snet-${var.project}-int-api-${var.environment}-${var.region}-01"
  resource_group_name               = var.resource_group
  virtual_network_name              = azurerm_virtual_network.vnet-proto-neu-01.name
  address_prefixes                  = ["10.100.10.64/29"]
  private_endpoint_network_policies = "Enabled"
  service_endpoints = [
    "Microsoft.AzureCosmosDB"
  ]

  delegation {
    name = "app-delegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "snet-proto-api-neu-01" {
  name                              = "snet-${var.project}-api-${var.environment}-${var.region}-01"
  resource_group_name               = var.resource_group
  virtual_network_name              = azurerm_virtual_network.vnet-proto-neu-01.name
  address_prefixes                  = ["10.100.10.96/29"]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet" "snet-proto-storage-neu-01" {
  name                              = "snet-${var.project}-st-${var.environment}-${var.region}-01"
  resource_group_name               = var.resource_group
  virtual_network_name              = azurerm_virtual_network.vnet-proto-neu-01.name
  address_prefixes                  = ["10.100.10.128/29"]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet" "snet-proto-redis-neu-01" {
  name                              = "snet-${var.project}-redis-${var.environment}-${var.region}-01"
  resource_group_name               = var.resource_group
  virtual_network_name              = azurerm_virtual_network.vnet-proto-neu-01.name
  address_prefixes                  = ["10.100.10.160/29"]
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_subnet" "snet-proto-cosmos-neu-01" {
  name                              = "snet-${var.project}-cosmos-${var.environment}-${var.region}-01"
  resource_group_name               = var.resource_group
  virtual_network_name              = azurerm_virtual_network.vnet-proto-neu-01.name
  address_prefixes                  = ["10.100.10.192/29"]
  private_endpoint_network_policies = "Enabled"
  service_endpoints = [
    "Microsoft.AzureCosmosDB"
  ]
}


resource "azurerm_network_security_group" "nsg-proto-api-neu-01" {
  name                = "nsg-${var.project}-api-${var.environment}-${var.region}-01"
  location            = var.region
  resource_group_name = var.resource_group

  security_rule {
    name                       = "AllowInboundHome"
    description                = ""
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "109.245.101.212"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "AllowInboundAzDevOps"
    description                = ""
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureDevOps"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsgassoc-proto-api-neu-01" {
  subnet_id                 = azurerm_subnet.snet-proto-api-neu-01.id
  network_security_group_id = azurerm_network_security_group.nsg-proto-api-neu-01.id
}

# resource "azurerm_network_security_group" "nsg-proto-int-api-neu-01" {
#   name                = "nsg-${var.project}-int-api-${var.environment}-${var.region}-01"
#   location            = var.region
#   resource_group_name = var.resource_group

#     security_rule {
#     name                       = "AllowInboundAzDevOps"
#     description                = ""
#     priority                   = 1001
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "*"
#     source_address_prefix      = "AzureDevOps"
#     destination_address_prefix = "*"
#   }
# }

# resource "azurerm_subnet_network_security_group_association" "nsgassoc-proto-int-api-neu-01" {
#   subnet_id                 = azurerm_subnet.snet-proto-int-api-neu-01.id
#   network_security_group_id = azurerm_network_security_group.nsg-proto-int-api-neu-01.id
# }

resource "azurerm_network_security_group" "nsg-proto-redis-neu-01" {
  name                = "nsg-${var.project}-redis-${var.environment}-${var.region}-01"
  location            = var.region
  resource_group_name = var.resource_group

  security_rule {
    name                       = "AllowAppService"
    description                = ""
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6379"
    source_address_prefix      = azurerm_subnet.snet-proto-int-api-neu-01.address_prefixes[0]
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "AllowAppServiceHTTPS"
    description                = ""
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = azurerm_subnet.snet-proto-int-api-neu-01.address_prefixes[0]
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsgassoc-proto-redis-neu-01" {
  subnet_id                 = azurerm_subnet.snet-proto-redis-neu-01.id
  network_security_group_id = azurerm_network_security_group.nsg-proto-redis-neu-01.id
}

resource "azurerm_network_security_group" "nsg-proto-cosmos-neu-01" {
  name                = "nsg-${var.project}-cosmos-${var.environment}-${var.region}-01"
  location            = var.region
  resource_group_name = var.resource_group

  security_rule {
    name                       = "AllowAPISubnet"
    description                = "Allow CosmosDb access from API subnet"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = azurerm_subnet.snet-proto-api-neu-01.address_prefixes[0]
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsgassoc-proto-cosmos-neu-01" {
  subnet_id                 = azurerm_subnet.snet-proto-cosmos-neu-01.id
  network_security_group_id = azurerm_network_security_group.nsg-proto-cosmos-neu-01.id
}

resource "azurerm_network_security_group" "nsg-proto-storage-neu-01" {
  name                = "nsg-${var.project}-storage-${var.environment}-${var.region}-01"
  location            = var.region
  resource_group_name = var.resource_group

  security_rule {
    name                       = "AllowAppService"
    description                = "Allow App service to talk to storage"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = azurerm_subnet.snet-proto-int-api-neu-01.address_prefixes[0]
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsgassoc-proto-storage-neu-01" {
  subnet_id                 = azurerm_subnet.snet-proto-storage-neu-01.id
  network_security_group_id = azurerm_network_security_group.nsg-proto-storage-neu-01.id
}

#DNS
resource "azurerm_private_dns_zone" "dnszone-proto-redis-neu-01" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = var.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnslink-proto-redis-neu-01" {
  name                  = "dnszlink-${var.project}-redis-${var.environment}-${var.region}-01"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.dnszone-proto-redis-neu-01.name
  virtual_network_id    = azurerm_virtual_network.vnet-proto-neu-01.id
}

resource "azurerm_private_dns_zone" "dnszone-proto-api-neu-01" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnslink-proto-api-neu-01" {
  name                  = "dnszlink-${var.project}-api-${var.environment}-${var.region}-01"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.dnszone-proto-api-neu-01.name
  virtual_network_id    = azurerm_virtual_network.vnet-proto-neu-01.id
}

resource "azurerm_private_dns_zone" "dnszone-proto-cosmos-neu-01" {
  name                = "privatelink.mongo.cosmos.azure.com"
  resource_group_name = var.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnslink-proto-cosmos-neu-01" {
  name                  = "dnszlink-${var.project}-cosmos-${var.environment}-${var.region}-01"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.dnszone-proto-cosmos-neu-01.name
  virtual_network_id    = azurerm_virtual_network.vnet-proto-neu-01.id
}

resource "azurerm_private_dns_zone" "dnszone-proto-storage-neu-01" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnslink-proto-storage-neu-01" {
  name                  = "dnszlink-${var.project}-storage-${var.environment}-${var.region}-01"
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.dnszone-proto-storage-neu-01.name
  virtual_network_id    = azurerm_virtual_network.vnet-proto-neu-01.id
}

#############################################################################
#############################################################################

output "api_subnet_id" {
  value = azurerm_subnet.snet-proto-api-neu-01.id
}

output "int_api_subnet_id" {
  value = azurerm_subnet.snet-proto-int-api-neu-01.id
}

output "cosmos_subnet_id" {
  value = azurerm_subnet.snet-proto-cosmos-neu-01.id
}

output "redis_subnet_id" {
  value = azurerm_subnet.snet-proto-redis-neu-01.id
}

output "storage_subnet_id" {
  value = azurerm_subnet.snet-proto-storage-neu-01.id
}

output "cosmos_private_dns_zone_id" {
  value = azurerm_private_dns_zone.dnszone-proto-cosmos-neu-01.id
}

output "cosmos_private_dns_zone_name" {
  value = azurerm_private_dns_zone.dnszone-proto-cosmos-neu-01.name
}

output "api_private_dns_zone_id" {
  value = azurerm_private_dns_zone.dnszone-proto-api-neu-01.id
}

output "api_private_dns_zone_name" {
  value = azurerm_private_dns_zone.dnszone-proto-api-neu-01.name
}

output "redis_private_dns_zone_id" {
  value = azurerm_private_dns_zone.dnszone-proto-redis-neu-01.id
}

output "redis_private_dns_zone_name" {
  value = azurerm_private_dns_zone.dnszone-proto-redis-neu-01.name
}

output "storage_private_dns_zone_id" {
  value = azurerm_private_dns_zone.dnszone-proto-storage-neu-01.id
}

output "storage_private_dns_zone_name" {
  value = azurerm_private_dns_zone.dnszone-proto-storage-neu-01.name
}


