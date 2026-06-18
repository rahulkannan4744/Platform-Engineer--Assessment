# Service Bus Namespace
resource "azurerm_servicebus_namespace" "sb" {
  name                = "sb-${var.prefix}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
}

# Service Bus Queue
resource "azurerm_servicebus_queue" "queue" {
  name         = "work-queue"
  namespace_id = azurerm_servicebus_namespace.sb.id

  batched_operations_enabled           = true
  dead_lettering_on_message_expiration = true
  max_delivery_count                   = 5
}

# RBAC Permissions for Managed Identity
resource "azurerm_role_assignment" "sb_data_owner" {
  scope                = azurerm_servicebus_namespace.sb.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}
