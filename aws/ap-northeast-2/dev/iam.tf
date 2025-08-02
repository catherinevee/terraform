
# IAM role for VPC Flow Logs
resource "aws_iam_role" "flow_log_role" {
  name = "${var.project_name}-${var.environment}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-flow-log-role"
  })
}

# IAM policy for VPC Flow Logs
resource "aws_iam_role_policy" "flow_log_policy" {
  name = "${var.project_name}-${var.environment}-flow-log-policy"
  role = aws_iam_role.flow_log_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}



# IAM role for log replication
resource "aws_iam_role" "log_replication" {
  count = local.is_primary_region && var.enable_multi_region ? 1 : 0
  name  = "${var.project_name}-${var.environment}-log-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-log-replication-role"
  })
}

# IAM policy for log replication
resource "aws_iam_role_policy" "log_replication" {
  count = local.is_primary_region && var.enable_multi_region ? 1 : 0
  name  = "${var.project_name}-${var.environment}-log-replication-policy"
  role  = aws_iam_role.log_replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents"
        ]
        Resource = [
          for region in var.secondary_regions :
          "arn:aws:logs:${region}:${data.aws_caller_identity.current.account_id}:*"
        ]
      }
    ]
  })
}