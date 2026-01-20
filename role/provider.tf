provider "aws" {
  region  = var.region
  profile = var.profile
  assume_role {
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.role_name}"
  }
}