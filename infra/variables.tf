variable "aws_region" {
  description = "AWS region where the Terraform state bucket is created"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
}

variable "state_bucket_key_prefix" {
  description = "Name of the S3 bucket key prefix for Terraform state"
  type        = string
}

variable "owner" {
  description = "Name of github repository owner"
  type        = string
}
