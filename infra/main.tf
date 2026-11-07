terraform {
  required_version = ">= 1.13"

  backend "s3" {
    bucket       = var.state_bucket_name
    key          = "${var.state_bucket_key_prefix}/terraform.tfstate"
    region       = var.aws_region
    encrypt      = true
    use_lockfile = true
  }
}

language {
  compatible_with {
    opentofu = ">= 1.13"
  }
}
