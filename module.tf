module "role" {
  source                    = "./role"
  region                    = var.region
  profile                   = var.profile
  aws_account_id            = var.aws_account_id
  assume_role_name          = var.assume_role_name
  role_name                 = var.role_name
  vpc_role_name             = var.vpc_role_name
  blog_role_name            = var.blog_role_name
  blog_deploy_role_name     = var.blog_deploy_role_name
  lambda_role_name          = var.lambda_role_name
  cost_notifier_role_name   = var.cost_notifier_role_name
  security_alarm_role_name  = var.security_alarm_role_name
  pr_bot_role_name          = var.pr_bot_role_name
  cdn_id                    = var.cdn_id
  blog_bucket_name          = var.blog_bucket_name
  log_bucket_name           = var.log_bucket_name
  cost_notifier_bucket_name = var.cost_notifier_bucket_name
  route53_hosted_zone_id    = var.route53_hosted_zone_id
  github_webhook_secret_name = var.github_webhook_secret_name
  github_private_key_name   = var.github_private_key_name
}

module "vpc" {
  source         = "./vpc"
  region         = var.region
  profile        = var.profile
  vpc_prefix     = var.vpc_prefix
  vpc_cidr       = var.vpc_cidr
  subnet_block   = var.subnet_block
  aws_role_arn   = module.role.assume_vpc_role_arn
}

module "cost_notifier" {
  source                    = "./cost-notifier"
  region                    = var.region
  profile                   = var.profile
  slack_webhook_url         = var.slack_webhook_url
  aws_role_arn              = module.role.assume_cost_notifier_role_arn
  cost_notifier_bucket_name = var.cost_notifier_bucket_name
  log_bucket_name           = var.log_bucket_name
}

module "security_alarm" {
  source            = "./security-alarm"
  region            = var.region
  profile           = var.profile
  aws_role_arn      = module.role.assume_security_alarm_role_arn
  slack_webhook_url = var.security_slack_webhook_url
}

module "pr_bot" {
  source            = "./pr-bot"
  region            = var.region
  profile           = var.profile
  aws_role_arn      = module.role.assume_pr_bot_role_arn
  slack_webhook_url = var.security_slack_webhook_url
  github_webhook_secret_name = var.github_webhook_secret_name
  github_private_key_name   = var.github_private_key_name
  github_app_id = var.github_app_id
  domain_name = var.domain_name
}
