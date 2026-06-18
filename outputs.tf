output "api_endpoint" {
  value       = "https://${azurerm_container_app.api_app.ingress[0].fqdn}"
  description = "The public URL endpoint of the API gateway service"
}
