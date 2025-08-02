# =============================================================================
# AWS CONFIGURATION
# =============================================================================
aws_region = "us-east-1"

# =============================================================================
# PROJECT CONFIGURATION
# =============================================================================
project_name = "my-cost-app"
environment = "prod"

# =============================================================================
# COST MANAGEMENT AND BUDGET CONFIGURATION
# =============================================================================
monthly_budget_limit = 200
budget_alert_thresholds = [50, 80, 100, 120]
budget_alert_emails = ["admin@example.com", "billing@example.com"]
enable_budget_alerts = true
budget_time_unit = "MONTHLY"

# =============================================================================
# INSTANCE CONFIGURATION (COST-OPTIMIZED)
# =============================================================================
instance_type = "t3.small"
preferred_ami_type = "amazon-linux-2023"
min_size = 1
max_size = 3
desired_capacity = 2

# =============================================================================
# MONITORING (DISABLE FOR COST SAVINGS IN DEV)
# =============================================================================
enable_detailed_monitoring = false
enable_alb_logging = true

# =============================================================================
# SPOT INSTANCE CONFIGURATION (70-90% COST SAVINGS)
# =============================================================================
enable_spot_instances = true
spot_instance_interruption_behavior = "terminate"
spot_max_price = ""  # Use current on-demand price as max

# =============================================================================
# DOMAIN AND SSL (OPTIONAL)
# =============================================================================
domain_name = ""  # Add your domain here if you have one

# =============================================================================
# COST ALLOCATION TAGS
# =============================================================================
default_tags = {
  Project     = "my-cost-app"
  Environment = "prod"
  Owner       = "platform-team"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
  Department  = "IT"
}

# =============================================================================
# ENVIRONMENT-SPECIFIC FEATURES (PRODUCTION EXAMPLE)
# =============================================================================
enable_nat_gateway = true
enable_waf = true
enable_backup = true
enable_ssl_redirect = false  # Set to true and provide certificate ARN for HTTPS
ssl_certificate_arn = ""     # Add your SSL certificate ARN here
enable_multi_az = true       # Enable for high availability