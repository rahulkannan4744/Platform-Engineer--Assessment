resource "azurerm_container_app" "api_app" {
  name                         = "ca-api-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity.id]
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 8080
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    container {
      name  = "api-gateway"
      image = "://microsoft.com"
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

      # 1. Liveness Probe (Uses initial_delay)
      liveness_probe {
        transport        = "HTTP"
        port             = 8080
        path             = "/health/live"
        initial_delay    = 5
        interval_seconds = 10
      }

      # 2. Readiness Probe (Uses initial_delay_seconds)
      readiness_probe {
        transport             = "HTTP"
        port                  = 8080
        path                  = "/health/ready"
        initial_delay_seconds = 5
        interval_seconds      = 10
      }
    }
  }
}
