data "archive_file" "security_alert_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "alert_lambda" {
  function_name    = "critical-event-alert-lambda"
  role             = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/HaramEventBridgeLambdaRole"
  handler          = "index.handler"
  runtime          = "nodejs22.x"
  filename         = data.archive_file.security_alert_lambda_zip.output_path
  source_code_hash = data.archive_file.security_alert_lambda_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }
}