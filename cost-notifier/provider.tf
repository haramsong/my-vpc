provider "aws" {
  region  = var.region
  profile = var.profile
  assume_role {
    role_arn = var.aws_role_arn
  }
}