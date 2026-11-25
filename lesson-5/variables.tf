variable "aws_region" {
  description = "AWS region for the workload."
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "Three availability zones in the selected region."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}
