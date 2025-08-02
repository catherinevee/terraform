# =============================================================================
# CORE PROJECT VARIABLES
# =============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default = "ap-northeast-2"
  validation {
    condition = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format like us-east-1."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "saturatedsky"
  validation {
    condition = can(regex("^[a-z0-9-]{3,63}$", var.project_name))
    error_message = "Project name must be 3-63 characters, lowercase alphanumeric and hyphens only."
  }
}

variable "environment" {
  description = "Environment (dev/staging/prod)"
  type        = string
  default     = ""
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "default_tags" {
  description = "Default tags for cost allocation and tracking"
  type        = map(string)
  default = {
    Project     = "saturatedsky"
    Environment = "dev"
    Owner       = "platform-team"
    ManagedBy   = "terraform"
    CostCenter  = "devteam"
  }
}

# =============================================================================
# INSTANCE AND COMPUTE VARIABLES
# =============================================================================

variable "instance_type" {
  description = "EC2 instance type (cost-optimized options)"
  type        = string
  default     = "t3.micro"
  validation {
    condition = contains([
      "t3.nano", "t3.micro", "t3.small", "t3.medium",
      "t4g.nano", "t4g.micro", "t4g.small", "t4g.medium"
    ], var.instance_type)
    error_message = "Instance type must be a cost-optimized option."
  }
}

variable "min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 1
  validation {
    condition     = var.min_size >= 0 && var.min_size <= 100
    error_message = "Minimum size must be between 0 and 100."
  }
}

variable "max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 3
  validation {
    condition     = var.max_size >= 1 && var.max_size <= 100
    error_message = "Maximum size must be between 1 and 100."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 1
  validation {
    condition     = var.desired_capacity >= 0 && var.desired_capacity <= 100
    error_message = "Desired capacity must be between 0 and 100."
  }
}

# =============================================================================
# MONITORING AND COST OPTIMIZATION VARIABLES
# =============================================================================

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring (additional cost)"
  type        = bool
  default     = false
}

variable "enable_spot_instances" {
  description = "Enable spot instances for significant cost savings (70-90% cheaper)"
  type        = bool
  default     = true
}

variable "spot_instance_interruption_behavior" {
  description = "Behavior when spot instances are interrupted"
  type        = string
  default     = "terminate"
  validation {
    condition     = contains(["hibernate", "stop", "terminate"], var.spot_instance_interruption_behavior)
    error_message = "Spot instance interruption behavior must be hibernate, stop, or terminate."
  }
}

variable "spot_max_price" {
  description = "Maximum price per hour for spot instances (empty for on-demand price)"
  type        = string
  default     = ""
}


# =============================================================================
# BUDGET AND COST CONTROL VARIABLES
# =============================================================================

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 100
  validation {
    condition     = var.monthly_budget_limit > 0 && var.monthly_budget_limit <= 10000
    error_message = "Monthly budget limit must be between 1 and 10,000 USD."
  }
}

variable "budget_alert_emails" {
  description = "List of email addresses for budget alerts"
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for email in var.budget_alert_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All budget alert emails must be valid email addresses."
  }
}

variable "budget_alert_thresholds" {
  description = "Budget alert thresholds as percentages"
  type        = list(number)
  default     = [50, 80, 100]
  validation {
    condition = alltrue([
      for threshold in var.budget_alert_thresholds : threshold > 0 && threshold <= 200
    ])
    error_message = "Budget thresholds must be between 1 and 200 percent."
  }
}

variable "enable_budget_alerts" {
  description = "Enable AWS Budget alerts for cost monitoring"
  type        = bool
  default     = true
}

variable "budget_time_unit" {
  description = "Time unit for the budget (MONTHLY, QUARTERLY, ANNUALLY)"
  type        = string
  default     = "MONTHLY"
  validation {
    condition     = contains(["MONTHLY", "QUARTERLY", "ANNUALLY"], var.budget_time_unit)
    error_message = "Budget time unit must be MONTHLY, QUARTERLY, or ANNUALLY."
  }
}

variable "budget_cost_filters" {
  description = "Cost filters for the budget (optional)"
  type = object({
    services          = optional(list(string), [])
    linked_accounts   = optional(list(string), [])
    usage_types       = optional(list(string), [])
    instance_types    = optional(list(string), [])
    regions           = optional(list(string), [])
  })
  default = {}
}


# =============================================================================
# DATA SOURCE RELATED VARIABLES
# =============================================================================

variable "domain_name" {
  description = "Domain name for SSL certificate and Route53 (optional)"
  type        = string
  default     = ""
  validation {
    condition = var.domain_name == "" || can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format (e.g., example.com) or empty string."
  }
}

variable "preferred_ami_type" {
  description = "Preferred AMI type for EC2 instances"
  type        = string
  default     = "amazon-linux-2023"
  validation {
    condition = contains([
      "amazon-linux-2023",
      "amazon-linux-2023-arm64", 
      "ubuntu-22.04",
      "windows-2022"
    ], var.preferred_ami_type)
    error_message = "AMI type must be one of: amazon-linux-2023, amazon-linux-2023-arm64, ubuntu-22.04, windows-2022."
  }
}

variable "enable_alb_logging" {
  description = "Enable ALB access logging to S3"
  type        = bool
  default     = true
}

variable "availability_zone_names" {
  description = "Specific availability zone names to use (optional - will use all available if empty)"
  type        = list(string)
  default     = []
}

# Environment-specific configuration variables
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets (production only)"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Enable WAF for ALB (production only)"
  type        = bool
  default     = false
}

variable "enable_backup" {
  description = "Enable backup policies (production only)"
  type        = bool
  default     = false
}

variable "enable_ssl_redirect" {
  description = "Enable SSL/TLS termination and redirect (production only)"
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "ARN of SSL certificate for HTTPS (required if enable_ssl_redirect is true)"
  type        = string
  default     = ""
}

variable "enable_multi_az" {
  description = "Enable multi-AZ deployment (production only)"
  type        = bool
  default     = false
}

# Local values for environment-specific configurations
locals {
  # Environment-based feature flags
  environment_config = {
    dev = {
      enable_nat_gateway   = false
      enable_waf          = false
      enable_backup       = false
      enable_ssl_redirect = false
      enable_multi_az     = false
      instance_type       = "t3.micro"
      min_size           = 1
      max_size           = 2
      desired_capacity   = 1
      monitoring_enabled = false
      log_retention_days = 7
    }
    staging = {
      enable_nat_gateway   = false
      enable_waf          = true
      enable_backup       = false
      enable_ssl_redirect = var.ssl_certificate_arn != ""
      enable_multi_az     = false
      instance_type       = "t3.small"
      min_size           = 1
      max_size           = 3
      desired_capacity   = 2
      monitoring_enabled = false
      log_retention_days = 14
    }
    prod = {
      enable_nat_gateway   = var.enable_nat_gateway
      enable_waf          = var.enable_waf
      enable_backup       = var.enable_backup
      enable_ssl_redirect = var.enable_ssl_redirect && var.ssl_certificate_arn != ""
      enable_multi_az     = var.enable_multi_az
      instance_type       = var.instance_type
      min_size           = var.min_size
      max_size           = var.max_size
      desired_capacity   = var.desired_capacity
      monitoring_enabled = var.enable_detailed_monitoring
      log_retention_days = 30
    }
  }
  
  # Current environment configuration
  current_config = local.environment_config[var.environment]
  
  # Multi-AZ subnet count
  subnet_count = local.current_config.enable_multi_az ? 3 : 2
}

# Multi-region configuration variables
variable "enable_multi_region" {
  description = "Enable multi-region deployment"
  type        = bool
  default     = false
}

variable "secondary_regions" {
  description = "List of secondary regions for multi-region deployment"
  type        = list(string)
  default     = ["ap-northeast-1"]
}

variable "enable_cross_region_backup" {
  description = "Enable cross-region backup replication"
  type        = bool
  default     = false
}

variable "enable_global_load_balancer" {
  description = "Enable AWS Global Accelerator for global load balancing"
  type        = bool
  default     = false
}

# Local values for multi-region configuration
locals {
  # Multi-region settings
  is_primary_region = var.aws_region == "ap-northeast-2"
  
  # Cross-region replication configuration
  replication_config = var.enable_multi_region ? {
    for region in var.secondary_regions : region => {
      region            = region
      backup_enabled    = var.enable_cross_region_backup
      monitoring_enabled = true
    }
  } : {}
}