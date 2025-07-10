variable "project_name" {
  default = "HaramVPC"
}

variable "region" {}

variable "profile" {
  default = null
}

variable "aws_role_arn" {
  sensitive = true
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

variable "number_of_vpc" {
  default = 0
}

variable "number_of_public_subnets" {
  default = 2
}

variable "number_of_private_subnets" {
  default = 2
}