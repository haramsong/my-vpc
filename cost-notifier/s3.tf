resource "aws_s3_bucket" "cost_notifier_bucket" {
  bucket = var.cost_notifier_bucket_name

  tags = {
    Name        = var.cost_notifier_bucket_name
    Environment = "Production"
  }
}

resource "aws_s3_bucket_public_access_block" "cost_notifier_bucket_acl" {
  bucket = aws_s3_bucket.cost_notifier_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket.cost_notifier_bucket]
}
