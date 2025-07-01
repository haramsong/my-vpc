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