# VPC Flow Logs for network monitoring
resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
  })
}

# CloudWatch Log Group for VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.project_name}-${var.environment}-flow-logs"
  retention_in_days = var.environment == "prod" ? 14 : 7

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
  })
}


# CloudWatch Insights query for analyzing flow logs
resource "aws_cloudwatch_query_definition" "top_talkers" {
  name = "${var.project_name}-${var.environment}-top-talkers"

  log_group_names = [
    aws_cloudwatch_log_group.vpc_flow_logs.name
  ]

  query_string = <<EOF
fields @timestamp, srcaddr, dstaddr, srcport, dstport, protocol, packets, bytes
| filter @message like /ACCEPT/
| stats sum(bytes) as total_bytes by srcaddr, dstaddr
| sort total_bytes desc
| limit 20
EOF
}

# CloudWatch metric filter for rejected traffic
resource "aws_cloudwatch_log_metric_filter" "rejected_traffic" {
  name           = "${var.project_name}-${var.environment}-rejected-traffic"
  log_group_name = aws_cloudwatch_log_group.vpc_flow_logs.name
  pattern        = "[version, account, eni, source, destination, srcport, destport, protocol, packets, bytes, windowstart, windowend, action="REJECT", flowlogstatus]"

  metric_transformation {
    name      = "RejectedPackets"
    namespace = "${var.project_name}/${var.environment}/Network"
    value     = "1"
  }
}

# CloudWatch alarm for high rejected traffic
resource "aws_cloudwatch_metric_alarm" "high_rejected_traffic" {
  alarm_name          = "${var.project_name}-${var.environment}-high-rejected-traffic"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RejectedPackets"
  namespace           = "${var.project_name}/${var.environment}/Network"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "High number of rejected network packets detected"
  treat_missing_data  = "notBreaching"

  tags = var.default_tags
}
# Data source for Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


# CloudWatch Alarms for auto scaling
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
  
  alarm_actions = [aws_autoscaling_policy.scale_up.arn]
  
  # Explicit dependency: Ensure ASG and scaling policy exist
  depends_on = [
    aws_autoscaling_group.main,
    aws_autoscaling_policy.scale_up
  ]
  
  tags = var.default_tags
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }
  
  alarm_actions = [aws_autoscaling_policy.scale_down.arn]
  
  # Explicit dependency: Ensure ASG and scaling policy exist
  depends_on = [
    aws_autoscaling_group.main,
    aws_autoscaling_policy.scale_down
  ]
  
  tags = var.default_tags
}

# CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dash"

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
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ALB Metrics"
          period  = 300
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
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.main.name],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EC2 Auto Scaling Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 6
        height = 6

        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", aws_autoscaling_group.main.name],
            [".", "GroupInServiceInstances", ".", "."],
            [".", "GroupTotalInstances", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Auto Scaling Group Size"
          period  = 300
        }
      }
    ]
  })

  depends_on = [
    aws_lb.main,
    aws_autoscaling_group.main
  ]

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-dash"
  })
}

# Custom CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}"
  retention_in_days = var.environment == "prod" ? 30 : 7

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-logs"
  })
}

# CloudWatch custom metric filter for application errors
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.project_name}-${var.environment}-errors"
  log_group_name = aws_cloudwatch_log_group.app_logs.name
  pattern        = "[timestamp, request_id, ERROR]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.project_name}/${var.environment}"
    value     = "1"
  }
}

# CloudWatch alarm for application errors
resource "aws_cloudwatch_metric_alarm" "app_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-app-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorCount"
  namespace           = "${var.project_name}/${var.environment}"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "High application error rate detected"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.budget_alert_emails != [] ? [aws_sns_topic.alerts[0].arn] : []

  depends_on = [aws_cloudwatch_log_metric_filter.error_count]

  tags = var.default_tags
}

# CloudWatch metric for multi-region monitoring
resource "aws_cloudwatch_metric_alarm" "cross_region_health" {
  count               = local.is_primary_region && var.enable_multi_region ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-cross-region-health"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Minimum"
  threshold           = "1"
  alarm_description   = "Cross-region health check failure"
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary[0].id
  }

  alarm_actions = length(var.budget_alert_emails) > 0 ? [aws_sns_topic.alerts[0].arn] : []

  tags = var.default_tags
}