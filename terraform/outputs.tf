output "lambda_code_bucket_name" {
  description = "Name of the S3 bucket for Lambda code"
  value       = aws_s3_bucket.lambda_code_bucket.id
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = var.initial_setup_complete ? aws_lambda_function.s3_trigger_lambda[0].arn : null
}