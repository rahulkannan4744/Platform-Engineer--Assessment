#!/bin/bash

# Exit instantly if any structural creation step encounters an error
set -e

echo "================================================================"
echo "🚀 Creating Real-World Terraform Project Architecture..."
echo "================================================================"

# 1. Define and establish the baseline workspace root directory path
TARGET_DIR="platform-infrastructure"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

echo "📂 Created directory: $TARGET_DIR/"

# 2. Compile and output providers.tf configuration block
cat << 'EOF' > providers.tf
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
EOF
echo "📄 Generated: providers.tf"

# 3. Compile and output variables.tf configuration block
cat << 'EOF' > variables.tf
variable "environment" {
  type        = string
  description = "Target deployment environment context"
  default     = "dev"
}

variable "location" {
  type        = string
  description = "Azure data center region"
  default     = "West US 2"
}

variable "prefix" {
  type        = string
  description = "Resource naming convention prefix tokens"
  default     = "platform"
}
EOF
echo "📄 Generated: variables.tf"

# 4. Compile and output terraform.tfvars configuration block
cat << 'EOF' > terraform.tfvars
environment = "dev"
location    = "westus2"
prefix      = "sre-assessment"
EOF
echo "📄 Generated: terraform.tfvars"

# 5. Compile and output main.tf configuration block
cat << 'EOF' > main.tf
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
EOF
echo "📄 Generated: main.tf"

# 6. Compile and output messaging.tf configuration block
cat << 'EOF' > messaging.tf
# Service Bus Namespace Component Broker Engine
resource "azurerm_servicebus_namespace" "sb" {
  name                = "sb-${var.prefix}-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
}

# Work Queue Broker Target
resource "azurerm_servicebus_queue" "queue" {
  name         = "work-queue"
  namespace_id = azurerm_servicebus_namespace.sb.id

  enable_batched_operations            = true
  dead_lettering_on_message_expiration = true
  max_delivery_count                   = 5
}

# Passwordless IAM Security Role Mapping
resource "azurerm_role_assignment" "sb_data_owner" {
  scope                = azurerm_servicebus_namespace.sb.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}
EOF
echo "📄 Generated: messaging.tf"

# 7. Compile and output api-service.tf configuration block
cat << 'EOF' > api-service.tf
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

      liveness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/health/live"
        initial_delay = 5
        interval_seconds = 10
      }

      readiness_probe {
        transport = "HTTP"
        port      = 8080
        path      = "/health/ready"
        initial_delay = 5
        interval_seconds = 10
      }
    }
  }
}
EOF
echo "📄 Generated: api-service.tf"

# 8. Compile and output worker-service.tf configuration block
cat << 'EOF' > worker-service.tf
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

