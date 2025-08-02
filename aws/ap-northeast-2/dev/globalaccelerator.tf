
# Global Accelerator (optional)
resource "aws_globalaccelerator_accelerator" "main" {
  count            = local.is_primary_region && var.enable_global_load_balancer ? 1 : 0
  name             = "${var.project_name}-${var.environment}-global-accelerator"
  ip_address_type  = "IPV4"
  enabled          = true

  attributes {
    flow_logs_enabled   = true
    flow_logs_s3_bucket = aws_s3_bucket.global_accelerator_logs[0].bucket
    flow_logs_s3_prefix = "flow-logs/"
  }

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-global-accelerator"
  })
}

# Global Accelerator listener
resource "aws_globalaccelerator_listener" "main" {
  count           = local.is_primary_region && var.enable_global_load_balancer ? 1 : 0
  accelerator_arn = aws_globalaccelerator_accelerator.main[0].id
  client_affinity = "SOURCE_IP"
  protocol        = "TCP"

  port_range {
    from = 80
    to   = 80
  }

  port_range {
    from = 443
    to   = 443
  }
}

# Global Accelerator endpoint group
resource "aws_globalaccelerator_endpoint_group" "main" {
  count                         = local.is_primary_region && var.enable_global_load_balancer ? 1 : 0
  listener_arn                  = aws_globalaccelerator_listener.main[0].id
  endpoint_group_region         = var.aws_region
  traffic_dial_percentage       = 100
  health_check_interval_seconds = 30
  health_check_path             = "/"
  health_check_protocol         = "HTTP"
  health_check_port             = 80
  threshold_count               = 3

  endpoint_configuration {
    endpoint_id = aws_lb.main.arn
    weight      = 100
  }
}
