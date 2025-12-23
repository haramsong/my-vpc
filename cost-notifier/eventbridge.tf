resource "aws_cloudwatch_event_rule" "daily_cost_notification" {
  name                = "daily-cost-notification"
  schedule_expression = "cron(0 0 * * ? *)"
}

resource "aws_cloudwatch_event_target" "daily_lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_cost_notification.name
  target_id = "sendDailyCost"
  arn       = aws_lambda_function.daily_cost_notifier.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.daily_cost_notifier.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_cost_notification.arn
}

resource "aws_cloudwatch_event_rule" "monthly_cost_notification" {
  name                = "monthly-cost-notify"
  schedule_expression = "cron(0 0 1 * ? *)"
}

resource "aws_cloudwatch_event_target" "monthly_lambda_target" {
  rule      = aws_cloudwatch_event_rule.monthly_cost_notification.name
  target_id = "costNotifier"
  arn       = aws_lambda_function.monthly_cost_notifier.arn
}

resource "aws_lambda_permission" "allow_event" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.monthly_cost_notifier.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monthly_cost_notification.arn
}

resource "aws_cloudwatch_event_rule" "cur_partition_repair" {
  name                = "cur-msck-repair-monthly"
  schedule_expression = "cron(0 0 5 * ? *)"
}

resource "aws_cloudwatch_event_target" "athena_msck" {
  rule     = aws_cloudwatch_event_rule.cur_partition_repair.name
  target_id = "AthenaMsckTarget"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/HaramEventbridgeAthenaMsckRole"
  arn      = "arn:aws:athena:${var.region}:${data.aws_caller_identity.current.account_id}:workgroup/primary"

  input = jsonencode({
    QueryString = "MSCK REPAIR TABLE cur_database.cost_and_usage_report;",
    QueryExecutionContext = {
      Database = "cur_database"
    },
    ResultConfiguration = {
      OutputLocation = "s3://${var.log_bucket_name}/msck/"
    }
  })
}