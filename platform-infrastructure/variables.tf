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
