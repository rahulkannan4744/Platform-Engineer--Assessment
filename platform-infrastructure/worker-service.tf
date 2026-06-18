resource "azurerm_container_app" "worker_app" {
  name                         = "ca-worker-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity.id]
  }

  template {
    container {
      name  = "background-worker"
      image = "://microsoft.com" # Fixed: Valid, clean placeholder image path
      cpu   = "0.25"
      memory = "0.5Gi"

      env {
        name  = "AZURE_CLIENT_ID"
        value = azurerm_user_assigned_identity.identity.client_id
      }
      env {
        name  = "ServiceBusConnection"
        value = "${azurerm_servicebus_namespace.sb.name}.servicebus.windows.net"
      }
      env {
        name  = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        value = azurerm_application_insights.appins.connection_string
      }
    }

    min_replicas = 0
    max_replicas = 5

    custom_scale_rule {
      name             = "sb-queue-trigger-rule"
      custom_rule_type = "azure-servicebus"
      metadata = {
        queueName    = "work-queue"
        messageCount = "5"
        namespace    = azurerm_servicebus_namespace.sb.name
      }
      authentication {
        secret_name       = "managed-identity-auth"
        trigger_parameter = "connection"
      }
    }
  }
}
