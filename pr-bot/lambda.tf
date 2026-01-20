data "archive_file" "dispatcher_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/dispatcher"
  output_path = "${path.module}/dist/dispatcher.zip"
}

data "archive_file" "step_zip" {
  for_each    = local.steps
  type        = "zip"
  source_dir  = "${path.module}/lambda/${each.key}"
  output_path = "${path.module}/dist/${each.key}.zip"
}

resource "aws_lambda_function" "dispatcher" {
  function_name = "${local.name}-webhook-dispatcher"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/HaramPRBotLambdaRole"
  runtime       = "nodejs22.x"
  handler       = "index.handler"

  filename         = data.archive_file.dispatcher_zip.output_path
  source_code_hash = data.archive_file.dispatcher_zip.output_base64sha256

  timeout     = 10
  memory_size = 256

  environment {
    variables = {
      WEBHOOK_SECRET_SSM_NAME = var.github_webhook_secret_name
      DEDUPE_TABLE_NAME = aws_dynamodb_table.github_webhook_delivery.name

      STEP_LINT_FUNCTION       = local.steps.lint
      STEP_TEST_FUNCTION       = local.steps.test
      STEP_DEPENDENCY_FUNCTION = local.steps.dependency
      STEP_REVIEW_FUNCTION     = local.steps.review

      GITHUB_APP_ID                   = var.github_app_id
      GITHUB_APP_PRIVATE_KEY_SSM_NAME = var.github_private_key_name
    }
  }

  depends_on = [
    data.archive_file.dispatcher_zip
  ]
}

resource "aws_lambda_function" "step" {
  for_each = local.steps

  function_name = each.value
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/HaramPRBotLambdaRole"
  runtime       = "nodejs22.x"
  handler       = "index.handler"

  filename         = data.archive_file.step_zip[each.key].output_path
  source_code_hash = data.archive_file.step_zip[each.key].output_base64sha256

  timeout     = 60
  memory_size = 512

  depends_on = [
    data.archive_file.step_zip
  ]
}