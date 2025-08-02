
# Backup plan (production only)
resource "aws_backup_vault" "main" {
  count       = local.current_config.enable_backup ? 1 : 0
  name        = "${var.project_name}-${var.environment}-backup-vault"
  kms_key_arn = aws_kms_key.backup[0].arn

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-backup-vault"
  })
}

resource "aws_kms_key" "backup" {
  count       = local.current_config.enable_backup ? 1 : 0
  description = "KMS key for backup encryption"

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-backup-key"
  })
}

resource "aws_backup_plan" "main" {
  count = local.current_config.enable_backup ? 1 : 0
  name  = "${var.project_name}-${var.environment}-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.main[0].name
    schedule          = "cron(0 2 ? * * *)"

    lifecycle {
      cold_storage_after = 30
      delete_after       = 120
    }

    recovery_point_tags = merge(var.default_tags, {
      BackupPlan = "${var.project_name}-${var.environment}-backup-plan"
    })
  }

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-backup-plan"
  })
}



# Route 53 health checks for multi-region
resource "aws_route53_health_check" "primary" {
  count                            = local.is_primary_region && var.enable_multi_region ? 1 : 0
  fqdn                            = aws_lb.main.dns_name
  port                            = 80
  type                            = "HTTP"
  resource_path                   = "/"
  failure_threshold               = "3"
  request_interval                = "30"
  cloudwatch_logs_region          = var.aws_region
  cloudwatch_alarm_region         = var.aws_region
  insufficient_data_health_status = "Failure"

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-health-check-primary"
  })
}
