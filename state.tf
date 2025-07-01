terraform {
  backend "s3" {
    bucket  = ""
    key     = "my-vpc/terraform.tfstate"
    region  = ""
    profile = ""
  }
}