provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source             = "./modules/vpc"
  vpc_name           = "lesson-5-vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = var.availability_zones
}

module "ecr" {
  source       = "./modules/ecr"
  ecr_name     = "devops-lesson-5-ecr"
  scan_on_push = true
}
