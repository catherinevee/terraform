# =============================================================================
# DATA SOURCES
# =============================================================================


# =============================================================================
# COMMON DATA SOURCES FOR AWS INFRASTRUCTURE
# =============================================================================

# Current AWS account information
data "aws_caller_identity" "current" {}

# Current AWS region
data "aws_region" "current" {}

# Current AWS partition (aws, aws-cn, aws-us-gov)
data "aws_partition" "current" {}

# Available Availability Zones in the current region
data "aws_availability_zones" "available" {
  state = "available"
  
  # Exclude zones that don't support all instance types
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Latest Amazon Linux 2023 AMI (ARM64)
data "aws_ami" "amazon_linux_2023_arm64" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

# Latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Latest Windows Server 2022 AMI
data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Default VPC (if exists)
data "aws_vpc" "default" {
  default = true
}

# Default security group
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = data.aws_vpc.default.id
}

# Current EC2 instance types available in the region
data "aws_ec2_instance_types" "available" {
  filter {
    name   = "current-generation"
    values = ["true"]
  }
  
  filter {
    name   = "instance-storage-supported"
    values = ["true", "false"]
  }
}

# SSL Certificate from ACM (if domain is provided)
data "aws_acm_certificate" "domain_cert" {
  count  = var.domain_name != "" ? 1 : 0
  domain = var.domain_name
  
  statuses = ["ISSUED"]
  
  most_recent = true
}

# Route53 hosted zone (if domain is provided)
data "aws_route53_zone" "domain" {
  count        = var.domain_name != "" ? 1 : 0
  name         = var.domain_name
  private_zone = false
}

# ELB service account for ALB logging
data "aws_elb_service_account" "main" {}

# Current IAM policy document for S3 bucket policy
data "aws_iam_policy_document" "s3_bucket_lb_logs" {
  count = var.enable_alb_logging ? 1 : 0
  
  statement {
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
    
    actions = [
      "s3:PutObject"
    ]
    
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${local.name_prefix}-alb-logs/*"
    ]
  }
  
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    
    actions = [
      "s3:PutObject"
    ]
    
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${local.name_prefix}-alb-logs/*"
    ]
    
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
  
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    
    actions = [
      "s3:GetBucketAcl"
    ]
    
    resources = [
      "arn:${data.aws_partition.current.partition}:s3:::${local.name_prefix}-alb-logs"
    ]
  }
}

# KMS key for encryption
data "aws_kms_key" "aws_managed_s3" {
  key_id = "alias/aws/s3"
}

data "aws_kms_key" "aws_managed_ebs" {
  key_id = "alias/aws/ebs"
}

data "aws_kms_key" "aws_managed_rds" {
  key_id = "alias/aws/rds"
}

# =============================================================================
# LOCALS
# =============================================================================


# =============================================================================
# LOCALS USING DATA SOURCES
# =============================================================================

locals {
  # Account and region information
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  partition  = data.aws_partition.current.partition
  
  # Availability zones - use specified ones or all available
  availability_zones = length(var.availability_zone_names) > 0 ? var.availability_zone_names : data.aws_availability_zones.available.names
  
  # Take only the first 3 AZs for most use cases
  selected_azs = slice(local.availability_zones, 0, min(length(local.availability_zones), 3))
  
  # AMI selection based on preferred type
  selected_ami_id = var.preferred_ami_type == "amazon-linux-2023" ? data.aws_ami.amazon_linux_2023.id :
                    var.preferred_ami_type == "amazon-linux-2023-arm64" ? data.aws_ami.amazon_linux_2023_arm64.id :
                    var.preferred_ami_type == "ubuntu-22.04" ? data.aws_ami.ubuntu_22_04.id :
                    var.preferred_ami_type == "windows-2022" ? data.aws_ami.windows_2022.id :
                    data.aws_ami.amazon_linux_2023.id  # fallback
  
  # Common resource naming
  name_prefix = "${var.project_name}-${var.environment}"
  
  # SSL and domain configuration
  has_domain = var.domain_name != ""
  ssl_certificate_arn = local.has_domain ? data.aws_acm_certificate.domain_cert[0].arn : ""
  hosted_zone_id = local.has_domain ? data.aws_route53_zone.domain[0].zone_id : ""
  
  # Common tags with account and region information
  common_tags = merge(var.default_tags, {
    AccountId     = local.account_id
    Region        = local.region
    Terraform     = "true"
    LastUpdated   = timestamp()
  })
  
  # ALB logging configuration
  alb_logs_bucket = var.enable_alb_logging ? "${local.name_prefix}-alb-logs" : ""
  
  # ELB service account ARN for the current region
  elb_service_account_arn = data.aws_elb_service_account.main.arn
}

# =============================================================================
# INFRASTRUCTURE RESOURCES
# =============================================================================

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}







