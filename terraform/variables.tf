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