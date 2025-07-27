output "vpc_id" {
  value = aws_vpc.main.id
}

output "bucket_name" {
  value = aws_s3_bucket.secure_bucket.id
}

output "role_arn" {
  value = aws_iam_role.example_role.arn
}