# AWS Configuration
aws_region = "ap-east-1"

# S3 Bucket Configuration
bucket_name = "apeast1-prod-catherine1"  # Must be globally unique
enable_versioning = true

# Tags
tags = {
  costowner = "IT"
  Environment = "prod"
  Project     = "s3"
  ManagedByTerraform   = true
}