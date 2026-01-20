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

variable "aws_role_arn" {
  sensitive = true
}

variable "slack_webhook_url" {
  sensitive = true
}
