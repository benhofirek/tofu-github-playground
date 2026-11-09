variable "aws_region" {
  description = "AWS region where the Terraform state bucket is created"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "tofu-github-terraform-state"
}

variable "state_bucket_key_prefix" {
  description = "Name of the S3 bucket key prefix for Terraform state"
  type        = string
  default     = "infrastructure"
}

variable "owner" {
  description = "Name of github repository owner"
  type        = string
  default     = "benhofirek"
}

variable "repository_name" {
  description = "Name of github repository owner"
  type        = string
  default     = "tofu-github-playground"
}

variable "opentofu_version" {
  description = "OpenTofu version to use"
  type        = number
  default     = 1.13
}

locals {
  state_key = "${var.state_bucket_key_prefix}/terraform.tfstate"
}
