resource "aws_iam_role" "lambda_exec_role" {
  name               = var.lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_relationship_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamo_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role" "lambda_cost_notifier_role" {
  name               = "HaramCostNotifierLambdaRole"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust_relationship_policy.json
}

data "aws_iam_policy_document" "lambda_cost_notify_policy" {
  statement {
    sid    = "AllowCostExplorerAccess"
    effect = "Allow"

    actions = [
      "ce:GetCostAndUsage"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowAthenaAccess"
    effect = "Allow"

    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowGlueCatalogAccess"
    effect = "Allow"

    actions = [
      "glue:GetDatabase",
      "glue:GetTable",
      "glue:GetPartition"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowPresignedUrlAccess"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
      "s3:CreateBucket",
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${var.cost_notifier_bucket_name}",
      "arn:aws:s3:::${var.cost_notifier_bucket_name}/*",
      "arn:aws:s3:::${var.log_bucket_name}",
      "arn:aws:s3:::${var.log_bucket_name}/*"
    ]
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_cost_notify_policy" {
  name        = "HaramLambdaCostNotifyPolicy"
  description = "Allow Lambda to read Cost Explorer data and write logs"
  policy      = data.aws_iam_policy_document.lambda_cost_notify_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_cost_notifier_permissions" {
  role       = aws_iam_role.lambda_cost_notifier_role.name
  policy_arn = aws_iam_policy.lambda_cost_notify_policy.arn
}

resource "aws_iam_role_policy_attachment" "cost_notifier_basic_execution" {
  role       = aws_iam_role.lambda_cost_notifier_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role" "lambda_security_alarm_role" {
  name = "HaramEventBridgeLambdaRole"

  assume_role_policy = data.aws_iam_policy_document.lambda_trust_relationship_policy.json
}

resource "aws_iam_role_policy_attachment" "security_alarm_basic_execution" {
  role       = aws_iam_role.lambda_security_alarm_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}