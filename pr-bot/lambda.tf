locals {
  # 프로젝트 공통 prefix
  name = "pr"

  # Step Lambda 이름 규칙
  # → IAM에서 prefix wildcard로 제어하기 위함
  steps = {
    lint       = "${local.name}-step-lint"
    test       = "${local.name}-step-test"
    dependency = "${local.name}-step-dependency"
    review     = "${local.name}-step-review"
  }

  # Lambda 소스 디렉토리 매핑
  # archive_file에서 사용
  step_source_dirs = {
    lint       = "lint"
    test       = "test"
    dependency = "dependency"
    review     = "review"
  }
}

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
  role          = "arn:aws:iam::${var.aws_account_id}:role/HaramPRBotLambdaRole"
  runtime       = "nodejs22.x"
  handler       = "index.handler"

  filename         = data.archive_file.dispatcher_zip.output_path
  source_code_hash = data.archive_file.dispatcher_zip.output_base64sha256

  timeout     = 10
  memory_size = 256

  environment {
    variables = {
      WEBHOOK_SECRET_SSM_NAME = var.github_webhook_secret_name

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
  role          = "arn:aws:iam::${var.aws_account_id}:role/HaramPRBotLambdaRole"
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