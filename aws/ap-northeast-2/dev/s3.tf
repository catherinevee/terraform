
# S3 bucket for cross-region state replication (primary region only)
resource "aws_s3_bucket" "terraform_state_replica" {
  count    = local.is_primary_region && var.enable_multi_region ? 1 : 0
  provider = aws.replica
  bucket   = "${var.project_name}-${var.environment}-terraform-state-replica"

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-terraform-state-replica"
    Purpose = "cross-region-replication"
  })
}

# S3 bucket versioning for state replica
resource "aws_s3_bucket_versioning" "terraform_state_replica" {
  count    = local.is_primary_region && var.enable_multi_region ? 1 : 0
  provider = aws.replica
  bucket   = aws_s3_bucket.terraform_state_replica[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption for state replica
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_replica" {
  count    = local.is_primary_region && var.enable_multi_region ? 1 : 0
  provider = aws.replica
  bucket   = aws_s3_bucket.terraform_state_replica[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# S3 bucket for Global Accelerator flow logs
resource "aws_s3_bucket" "global_accelerator_logs" {
  count  = local.is_primary_region && var.enable_global_load_balancer ? 1 : 0
  bucket = "${var.project_name}-${var.environment}-global-accelerator-logs"

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-global-accelerator-logs"
  })
}
