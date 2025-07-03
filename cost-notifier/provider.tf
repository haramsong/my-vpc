provider "aws" {
  region  = var.region
  profile = var.profile
  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/${var.cost_notifier_role_name}"
  }
}