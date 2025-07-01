variable "project_name" {
  default = "haram"
}

variable "region" {}

variable "profile" {}

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