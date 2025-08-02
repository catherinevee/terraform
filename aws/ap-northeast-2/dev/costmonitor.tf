
# =============================================================================
# STANDARDIZED BUDGET ALERTS AND COST MONITORING
# =============================================================================

# SNS Topic for Budget Alerts
resource "aws_sns_topic" "budget_alerts" {
  count = var.enable_budget_alerts && length(var.budget_alert_emails) > 0 ? 1 : 0
  
  name         = "${local.name_prefix}-budget-alerts"
  display_name = "${var.project_name} Budget Alerts"
  
  tags = merge(var.default_tags, {
    Name        = "${local.name_prefix}-budget-alerts"
    Purpose     = "Budget and cost monitoring"
    AlertType   = "Financial"
  })
}

# SNS Topic Subscriptions for Email Alerts
resource "aws_sns_topic_subscription" "budget_email_alerts" {
  count = var.enable_budget_alerts && length(var.budget_alert_emails) > 0 ? length(var.budget_alert_emails) : 0
  
  topic_arn = aws_sns_topic.budget_alerts[0].arn
  protocol  = "email"
  endpoint  = var.budget_alert_emails[count.index]
}

# AWS Budget with Multiple Alert Thresholds
resource "aws_budgets_budget" "main" {
  count = var.enable_budget_alerts ? 1 : 0
  
  name         = "${local.name_prefix}-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = var.budget_time_unit
  
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())
  
  # Cost filters (optional)
  dynamic "cost_filters" {
    for_each = var.budget_cost_filters.services != [] || 
               var.budget_cost_filters.linked_accounts != [] ||
               var.budget_cost_filters.usage_types != [] ||
               var.budget_cost_filters.instance_types != [] ||
               var.budget_cost_filters.regions != [] ? [1] : []
    
    content {
      service          = var.budget_cost_filters.services
      linked_account   = var.budget_cost_filters.linked_accounts
      usage_type       = var.budget_cost_filters.usage_types
      instance_type    = var.budget_cost_filters.instance_types
      region           = var.budget_cost_filters.regions
      
      # Filter by project tags
      tag {
        key    = "Project"
        values = [var.project_name]
      }
      
      tag {
        key    = "Environment"
        values = [var.environment]
      }
    }
  }
  
  # Multiple notification thresholds
  dynamic "notification" {
    for_each = var.enable_budget_alerts && length(var.budget_alert_emails) > 0 ? var.budget_alert_thresholds : []
    
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                 = notification.value
      threshold_type            = "PERCENTAGE"
      notification_type         = "ACTUAL"
      subscriber_email_addresses = var.budget_alert_emails
      subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts[0].arn]
    }
  }
  
  # Forecasted budget alerts
  dynamic "notification" {
    for_each = var.enable_budget_alerts && length(var.budget_alert_emails) > 0 ? [100] : []
    
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                 = notification.value
      threshold_type            = "PERCENTAGE"
      notification_type          = "FORECASTED"
      subscriber_email_addresses = var.budget_alert_emails
      subscriber_sns_topic_arns  = [aws_sns_topic.budget_alerts[0].arn]
    }
  }
  
  tags = merge(var.default_tags, {
    Name        = "${local.name_prefix}-budget"
    Purpose     = "Cost monitoring and alerting"
    BudgetType  = "Monthly"
  })
}

# Cost Anomaly Detection
resource "aws_ce_anomaly_detector" "main" {
  count = var.enable_budget_alerts ? 1 : 0
  
  name         = "${local.name_prefix}-anomaly-detector"
  monitor_type = "DIMENSIONAL"
  
  specification = jsonencode({
    Dimension = "SERVICE"
    MatchOptions = ["EQUALS"]
    Values = ["EC2-Instance", "ElasticLoadBalancing", "AmazonRDS", "AmazonS3"]
    Tags = {
      Project     = var.project_name
      Environment = var.environment
    }
  })
  
  tags = merge(var.default_tags, {
    Name    = "${local.name_prefix}-anomaly-detector"
    Purpose = "Cost anomaly detection"
  })
}

# Cost Anomaly Subscription
resource "aws_ce_anomaly_subscription" "main" {
  count = var.enable_budget_alerts && length(var.budget_alert_emails) > 0 ? 1 : 0
  
  name      = "${local.name_prefix}-anomaly-subscription"
  frequency = "DAILY"
  
  monitor_arn_list = [
    aws_ce_anomaly_detector.main[0].arn
  ]
  
  subscriber {
    type    = "EMAIL"
    address = var.budget_alert_emails[0]  # Primary email for anomalies
  }
  
  threshold_expression {
    and {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
        values        = ["100"]  # Alert for anomalies > $100
        match_options = ["GREATER_THAN_OR_EQUAL"]
      }
    }
  }
  
  tags = merge(var.default_tags, {
    Name    = "${local.name_prefix}-anomaly-subscription"
    Purpose = "Cost anomaly alerting"
  })
}

# CloudWatch Dashboard for Cost Monitoring
resource "aws_cloudwatch_dashboard" "cost_monitoring" {
  count = var.enable_budget_alerts ? 1 : 0
  
  dashboard_name = "${local.name_prefix}-cost-monitoring"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ]
          period = 86400
          stat   = "Maximum"
          region = "us-east-1"  # Billing metrics are only available in us-east-1
          title  = "Estimated Monthly Charges"
          view   = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn"],
            ["AWS/EC2", "NetworkOut"],
            ["AWS/EC2", "CPUUtilization"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "EC2 Usage Metrics"
          view   = "timeSeries"
        }
      }
    ]
  })
  
  tags = merge(var.default_tags, {
    Name    = "${local.name_prefix}-cost-dashboard"
    Purpose = "Cost and usage monitoring"
  })
}

# Budget for cost control
resource "aws_budgets_budget" "main" {
  count = length(var.budget_alert_emails) > 0 ? 1 : 0
  
  name       = "${var.project_name}-${var.environment}-budget"
  budget_type = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  
  cost_filters = {
    Tag = [
      "Project:${var.project_name}",
      "Environment:${var.environment}"
    ]
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_alert_emails
  }
}
