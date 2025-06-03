variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "eu-west-2"
}

variable "bucket_prefix" {
  description = "Prefix for S3 bucket name"
  default     = "lambda-code-bucket"
}

variable "initial_setup_complete" {
  description = "Flag to indicate if initial setup (bucket creation) is complete"
  type        = bool
  default     = false
}