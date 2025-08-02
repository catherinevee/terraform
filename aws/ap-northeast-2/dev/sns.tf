
# SNS topic for alerts (conditional)
resource "aws_sns_topic" "alerts" {
  count = length(var.budget_alert_emails) > 0 ? 1 : 0
  name  = "${var.project_name}-${var.environment}-alerts"

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-alerts"
  })
}

# SNS subscriptions for alert emails
resource "aws_sns_topic_subscription" "email_alerts" {
  count     = length(var.budget_alert_emails)
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.budget_alert_emails[count.index]
}