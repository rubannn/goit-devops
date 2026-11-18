variable "aws_region" {
  description = "AWS region for the workload."
  type        = string
  default     = "us-west-2"
}

variable "availability_zones" {
  description = "Three availability zones in the selected region."
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}
