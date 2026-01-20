data "aws_caller_identity" "current" {}

data "aws_acm_certificate" "my_certificate" {
  domain      = "*.${var.domain_name}"
  statuses    = ["ISSUED"]
  most_recent = true
}