variable "aws_region" {
  description = "AWS region for the backend resources."
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally unique name for the Terraform state bucket."
  type        = string
  default     = "devops-rnn-s3-lesson7"
}

variable "table_name" {
  description = "DynamoDB table used for Terraform state locking."
  type        = string
  default     = "devops-rnn-terraform-locks-lesson7"
}
