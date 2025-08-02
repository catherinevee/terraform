
# Launch Template with cost optimization
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-${var.environment}-"
  description   = "Launch template for ${var.project_name} ${var.environment}"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  # Spot instance configuration for cost optimization (70-90% savings)
  dynamic "instance_market_options" {
    for_each = var.enable_spot_instances ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        instance_interruption_behavior = var.spot_instance_interruption_behavior
        max_price                       = var.spot_max_price != "" ? var.spot_max_price : null
        spot_instance_type              = "one-time"
      }
    }
  }
  
  # Cost optimization: Use GP3 storage instead of GP2
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp3"
      volume_size           = 8
      encrypted             = true
      delete_on_termination = true
    }
  }
  
  monitoring {
    enabled = var.enable_detailed_monitoring
  }
  
  # Simple web server user data
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from ${var.project_name} - ${var.environment}</h1>" > /var/www/html/index.html
              EOF
  )
  
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.default_tags, {
      Name = "${var.project_name}-${var.environment}-instance"
    })
  }
  
  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-lt"
  })
}

# Auto Scaling Group with cost-optimized configuration
resource "aws_autoscaling_group" "main" {
  name                = "${var.project_name}-${var.environment}-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.main.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300
  
  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity
  
  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  
  # Explicit dependencies: Ensure all prerequisites are ready
  depends_on = [
    aws_launch_template.main,
    aws_lb_target_group.main,
    aws_subnet.public,
    aws_security_group.web
  ]
  
  # Cost optimization: Scale down quickly when not needed
  default_cooldown = 180
  
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg"
    propagate_at_launch = false
  }
  
  dynamic "tag" {
    for_each = var.default_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Auto Scaling Policies for cost optimization
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-${var.environment}-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-${var.environment}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.main.name
}
