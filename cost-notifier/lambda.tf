data "archive_file" "daily_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/daily"
  output_path = "${path.module}/daily.zip"
}

resource "aws_lambda_function" "daily_cost_notifier" {
  function_name    = "daily-cost-notifier"
  role             = "arn:aws:iam::${var.aws_account_id}:role/HaramCostNotifierLambdaRole"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.daily_lambda_zip.output_path
  source_code_hash = data.archive_file.daily_lambda_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }
}

data "archive_file" "monthly_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/monthly"
  output_path = "${path.module}/monthly.zip"
}

resource "aws_lambda_function" "monthly_cost_notifier" {
  function_name    = "monthly-cost-notifier"
  role             = "arn:aws:iam::${var.aws_account_id}:role/HaramCostNotifierLambdaRole"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.monthly_lambda_zip.output_path
  source_code_hash = data.archive_file.monthly_lambda_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      REGION            = var.region
      REPORT_BUCKET     = var.cost_notifier_bucket_name
      LOG_BUCKET        = var.log_bucket_name
    }
  }
}
