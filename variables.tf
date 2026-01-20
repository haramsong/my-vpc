variable "project_name" {
  default = "HaramProject"
}

variable "region" {}

variable "profile" {
  default = null
}

variable "aws_account_id" {
  sensitive = true
}

variable "vpc_cidr" {
  sensitive = true
}

variable "vpc_prefix" {
  sensitive = true
}

variable "subnet_block" {
  sensitive = true
}

variable "role_name" {
  sensitive = true
}

variable "assume_role_name" {
  sensitive = true
}

variable "vpc_role_name" {
  sensitive = true
}

variable "blog_role_name" {
  sensitive = true
}

variable "blog_deploy_role_name" {
  sensitive = true
}

variable "lambda_role_name" {
  sensitive = true
}

variable "cost_notifier_role_name" {
  sensitive = true
}

variable "security_alarm_role_name" {
  sensitive = true
}

variable "pr_bot_role_name" {
  sensitive = true
}

variable "cdn_id" {
  sensitive = true
}

variable "blog_bucket_name" {
  sensitive = true
}

variable "log_bucket_name" {
  sensitive = true
}

variable "cost_notifier_bucket_name" {
  sensitive = true
}

variable "route53_hosted_zone_id" {
  sensitive = true
}

variable "slack_webhook_url" {
  sensitive = true
}

variable "security_slack_webhook_url" {
  sensitive = true
}

variable "github_webhook_secret_name" {
  sensitive = true
}

variable "github_private_key_name" {
  sensitive = true
}

variable "github_app_id" {
  sensitive = true
}

variable "domain_name" {
  sensitive = true
}