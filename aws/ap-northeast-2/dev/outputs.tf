output "application_url" {
  description = "URL of the application load balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "security_group_alb_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "security_group_web_id" {
  description = "ID of the web tier security group"
  value       = aws_security_group.web.id
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "autoscaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "vpc_flow_logs_group_name" {
  description = "Name of the VPC Flow Logs CloudWatch log group"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "vpc_flow_logs_iam_role_arn" {
  description = "ARN of the VPC Flow Logs IAM role"
  value       = aws_iam_role.flow_log_role.arn
}

output "network_insights_query_name" {
  description = "Name of the CloudWatch Insights query for network analysis"
  value       = aws_cloudwatch_query_definition.top_talkers.name
}


# =============================================================================
# BUDGET AND COST MONITORING OUTPUTS
# =============================================================================

output "budget_name" {
  description = "Name of the AWS Budget"
  value       = var.enable_budget_alerts ? aws_budgets_budget.main[0].name : null
}

output "budget_arn" {
  description = "ARN of the AWS Budget"
  value       = var.enable_budget_alerts ? aws_budgets_budget.main[0].arn : null
}

output "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  value       = var.monthly_budget_limit
}

output "budget_alert_thresholds" {
  description = "Budget alert thresholds configured"
  value       = var.budget_alert_thresholds
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for budget alerts"
  value       = var.enable_budget_alerts && length(var.budget_alert_emails) > 0 ? aws_sns_topic.budget_alerts[0].arn : null
}

output "cost_anomaly_detector_arn" {
  description = "ARN of the cost anomaly detector"
  value       = var.enable_budget_alerts ? aws_ce_anomaly_detector.main[0].arn : null
}

output "cost_monitoring_dashboard_url" {
  description = "URL to the cost monitoring CloudWatch dashboard"
  value       = var.enable_budget_alerts ? "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.cost_monitoring[0].dashboard_name}" : null
}


# =============================================================================
# DATA SOURCE OUTPUTS
# =============================================================================

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}

output "aws_partition" {
  description = "AWS Partition"
  value       = data.aws_partition.current.partition
}

output "availability_zones" {
  description = "Available Availability Zones"
  value       = data.aws_availability_zones.available.names
}

output "selected_availability_zones" {
  description = "Selected Availability Zones for deployment"
  value       = local.selected_azs
}

output "selected_ami_id" {
  description = "Selected AMI ID based on preferred type"
  value       = local.selected_ami_id
}

output "selected_ami_name" {
  description = "Selected AMI name"
  value = var.preferred_ami_type == "amazon-linux-2023" ? data.aws_ami.amazon_linux_2023.name :
          var.preferred_ami_type == "amazon-linux-2023-arm64" ? data.aws_ami.amazon_linux_2023_arm64.name :
          var.preferred_ami_type == "ubuntu-22.04" ? data.aws_ami.ubuntu_22_04.name :
          var.preferred_ami_type == "windows-2022" ? data.aws_ami.windows_2022.name :
          data.aws_ami.amazon_linux_2023.name
}

output "ssl_certificate_arn" {
  description = "SSL Certificate ARN (if domain is provided)"
  value       = local.has_domain ? data.aws_acm_certificate.domain_cert[0].arn : null
  sensitive   = false
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID (if domain is provided)"
  value       = local.has_domain ? data.aws_route53_zone.domain[0].zone_id : null
}

output "elb_service_account_arn" {
  description = "ELB service account ARN for ALB logging"
  value       = data.aws_elb_service_account.main.arn
}

output "cost_allocation_tags" {
  description = "Tags used for cost allocation"
  value       = var.default_tags
}