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

variable "aws_role_arn" {
  sensitive = true
}

variable "slack_webhook_url" {
  sensitive = true
}

variable "cost_notifier_bucket_name" {
  sensitive = true
}

variable "log_bucket_name" {
  sensitive = true
}