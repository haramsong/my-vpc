variable "project_name" {
  default = "HaramRole"
  type    = string
}

variable "region" {
  type = string
}

variable "profile" {
  sensitive = true
}

variable "aws_account_id" {
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