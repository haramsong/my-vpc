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

resource "aws_cloudwatch_event_rule" "cur_msck" {
  name                = "cur-msck-monthly"
  schedule_expression = "cron(0 0 5 * ? *)"
}

resource "aws_cloudwatch_event_target" "msck_lambda" {
  rule      = aws_cloudwatch_event_rule.cur_msck.name
  target_id = "msckMonthly"
  arn       = aws_lambda_function.athena_msck.arn
}

resource "aws_lambda_permission" "allow_msck_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.athena_msck.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cur_msck.arn
}