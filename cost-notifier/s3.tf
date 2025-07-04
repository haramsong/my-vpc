resource "aws_s3_bucket" "athena_query_results" {
  bucket = var.log_bucket_name
}

resource "aws_s3_bucket_public_access_block" "log_bucket_acl" {
  bucket = aws_s3_bucket.athena_query_results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_log_lifecycle" {
  bucket = aws_s3_bucket.athena_query_results.id

  rule {
    id     = "expire_athena_logs_daily"
    status = "Enabled"

    expiration {
      days = 1
    }

    filter {
      prefix = ""
    }
  }
}


resource "aws_s3_bucket_policy" "my_lop_bucket_policy" {
  bucket = aws_s3_bucket.athena_query_results.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "athena.amazonaws.com"
        },
        Action   = "s3:*",
        Resource = [
          "arn:aws:s3:::${var.log_bucket_name}",
          "arn:aws:s3:::${var.log_bucket_name}/*",
          ]
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.log_bucket_acl]
}
