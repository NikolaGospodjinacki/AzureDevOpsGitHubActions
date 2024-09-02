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

variable "api_app_id" {
  type = string
}

#############################################################################
#############################################################################

# Log Analytics
resource "azurerm_log_analytics_workspace" "log-proto-weu-01" {
  name                = "log-${var.project}-${var.environment}-${var.region}-01"
  location            = var.region
  resource_group_name = var.resource_group
  sku                 = "PerGB2018"
  retention_in_days   = 7
}

resource "azurerm_monitor_diagnostic_setting" "monitor-proto-weu-01" {
  name                       = "${var.project}-${var.environment}-${var.region}-01 API Application Logs"
  target_resource_id         = var.api_app_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log-proto-weu-01.id

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  enabled_log {
    category = "AppServiceHTTPLogs"

  }
}