variable "project_name" {
  default = "HaramSecurityAlarm"
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

variable "aws_role_arn" {
  sensitive = true
}

variable "slack_webhook_url" {
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

variable "acm_id" {
  sensitive = true
}