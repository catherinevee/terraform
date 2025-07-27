variable "aws_region" {
  description = "AWS region for resources (CloudFront will use us-east-1 for certificates)"
  type        = string
  default = "ap-east-1"
  validation {
    condition = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format like us-east-1."
  }
}

variable "project_name" {
  description = "Name of the project (will be used for S3 bucket naming)"
  type        = string
  default     = "dev-catherineitcom"
  validation {
    condition = can(regex("^[a-z0-9-]{3,63}$", var.project_name))
    error_message = "Project name must be 3-63 characters, lowercase alphanumeric and hyphens only."
  }
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]{3,63}$", var.bucket_name))
    error_message = "Bucket name must be 3-63 characters, lowercase alphanumeric, dots, and hyphens only."
  }
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}


variable "default_tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default = {
    Project     = "placeholder"
    Environment = "dev"
    Owner       = "IT"
    ManagedBy   = "terraform"
  }
}