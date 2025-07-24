variable "aws_region" {
  type = string
  default = "ap-northeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = ""
  
  validation {
    condition     = contains(["dev", "staging", "prod", "test"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, test."
  }
}

variable "project" {
  description = "Project name"
  type        = string
  default     = ""
  
  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 50
    error_message = "Project name must be between 1 and 50 characters long."
  }
}

variable "region" {
  description = "AWS/Azure region"
  type        = string
  default     = ""
  
  validation {
    condition     = length(var.region) > 0
    error_message = "Region must be specified."
  }
}

variable "costcenter" {
  description = "Cost center for resource billing"
  type        = string
  default     = ""
  
  validation {
    condition     = length(var.costcenter) > 0
    error_message = "Cost center must be specified."
  }
}

locals {
  default_tags = {
    Environment = var.environment
    Project     = var.project
    Region      = var.region
    CostCenter  = var.costcenter
  }
}