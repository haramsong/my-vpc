resource "aws_dynamodb_table" "github_webhook_delivery" {
  name         = "${local.name}-github-webhook-delivery"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "delivery_id"

  attribute {
    name = "delivery_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }
}