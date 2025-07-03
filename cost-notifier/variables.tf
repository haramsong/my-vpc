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

variable "cost_notifier_role_name" {
  sensitive = true
}
