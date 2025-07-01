module "role" {
  source         = "./role"
  region         = var.region
  profile        = var.profile
  aws_account_id = var.aws_account_id
  assume_role_name = var.assume_role_name
  role_name      = var.role_name
  vpc_role_name  = var.vpc_role_name
}

module "vpc" {
  source         = "./vpc"
  region         = var.region
  profile = var.profile
  aws_account_id = var.aws_account_id
  vpc_prefix     = var.vpc_prefix
  vpc_cidr       = var.vpc_cidr
  subnet_block   = var.subnet_block
  aws_role_arn   = module.role.assume_vpc_role_arn
}

