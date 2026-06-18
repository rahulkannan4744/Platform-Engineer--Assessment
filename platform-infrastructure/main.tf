data "azurerm_client_config" "current" {}

# 1. Isolated Resource Group Context
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.prefix}-${var.environment}"
  location = var.location
}

# 2. Central Identity Matrix (User-Assigned Managed Identity)
resource "azurerm_user_assigned_identity" "identity" {
  name                = "id-${var.prefix}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# 3. Observability Log Workspace Core
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${var.prefix}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# 4. Distributed Tracing Application Insights Platform Component
resource "azurerm_application_insights" "appins" {
  name                = "appi-${var.prefix}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
}

# 5. Hosting Container App Environment Instance
resource "azurerm_container_app_environment" "cae" {
  name                       = "cae-${var.prefix}-${var.environment}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}
