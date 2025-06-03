terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Create S3 bucket for Lambda code (first step)
resource "aws_s3_bucket" "lambda_code_bucket" {
  bucket        = "${var.bucket_prefix}-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Lambda resources (created after initial setup)
resource "aws_lambda_function" "s3_trigger_lambda" {
  count = var.initial_setup_complete ? 1 : 0

  function_name = "s3-object-change-handler-python"
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.9"
  timeout       = 10
  memory_size   = 128

  s3_bucket = aws_s3_bucket.lambda_code_bucket.id
  s3_key    = "lambda-code.zip"

  role = aws_iam_role.lambda_exec_role[0].arn

  depends_on = [
    aws_s3_bucket.lambda_code_bucket
  ]
}

resource "aws_iam_role" "lambda_exec_role" {
  count = var.initial_setup_complete ? 1 : 0

  name = "lambda_exec_role_python"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count = var.initial_setup_complete ? 1 : 0

  role       = aws_iam_role.lambda_exec_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "s3_read_policy" {
  count = var.initial_setup_complete ? 1 : 0

  name = "s3_read_policy"
  role = aws_iam_role.lambda_exec_role[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.lambda_code_bucket.arn,
          "${aws_s3_bucket.lambda_code_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count = var.initial_setup_complete ? 1 : 0

  bucket = aws_s3_bucket.lambda_code_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_trigger_lambda[0].arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}

resource "aws_lambda_permission" "allow_bucket" {
  count = var.initial_setup_complete ? 1 : 0

  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_trigger_lambda[0].arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.lambda_code_bucket.arn
}