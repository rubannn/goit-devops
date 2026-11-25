variable "vpc_name" {
  type = string
}
variable "vpc_cidr_block" {
  type = string
}
variable "public_subnets" {
  type = list(string)
  validation {
    condition     = length(var.public_subnets) == 3
    error_message = "Provide exactly three public subnet CIDRs."
  }
}
variable "private_subnets" {
  type = list(string)
  validation {
    condition     = length(var.private_subnets) == 3
    error_message = "Provide exactly three private subnet CIDRs."
  }
}
variable "availability_zones" {
  type = list(string)
  validation {
    condition     = length(var.availability_zones) == 3 && length(distinct(var.availability_zones)) == 3
    error_message = "Provide three distinct availability zones."
  }
}
variable "public_subnet_extra_tags" {
  description = "Extra tags merged onto every public subnet (e.g. EKS/ELB discovery tags)."
  type        = map(string)
  default     = {}
}
variable "private_subnet_extra_tags" {
  description = "Extra tags merged onto every private subnet (e.g. EKS/ELB discovery tags)."
  type        = map(string)
  default     = {}
}
