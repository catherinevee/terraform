
# WAF for ALB (staging and production)
resource "aws_wafv2_web_acl" "main" {
  count = local.current_config.enable_waf ? 1 : 0
  name  = "${var.project_name}-${var.environment}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitRule"
    priority = 1

    override_action {
      none {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }

    action {
      block {}
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-waf"
  })

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "MainWebACL"
    sampled_requests_enabled   = true
  }
}

# WAF association with ALB (conditional)
resource "aws_wafv2_web_acl_association" "main" {
  count        = local.current_config.enable_waf ? 1 : 0
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main[0].arn
}
