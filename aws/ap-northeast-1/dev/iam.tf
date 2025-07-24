
# IAM role with least privilege
resource "aws_iam_role" "example_role" {
  name = "${var.environment}-example-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "example_policy" {
  name = "${var.environment}-example-policy"
  role = aws_iam_role.example_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["s3:GetObject"]
      Effect   = "Allow"
      Resource = "${aws_s3_bucket.secure_bucket.arn}/*"
    }]
  })
}