terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3_backend" {
  source      = "../modules/s3-backend"
  bucket_name = var.bucket_name
  table_name  = var.table_name
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "bucket_name" {
  description = "Globally unique name for the Terraform state bucket."
  type        = string
}

variable "table_name" {
  type    = string
  default = "terraform-locks"
}

output "bucket_url" {
  value = module.s3_backend.bucket_url
}

output "dynamodb_table_name" {
  value = module.s3_backend.dynamodb_table_name
}
