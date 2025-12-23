terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket  = ""
    key     = "my-vpc/terraform.tfstate"
    region  = ""
    profile = ""
  }
}