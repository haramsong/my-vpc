data "aws_iam_policy_document" "cost_notifier_workspace_role_policy" {
  statement {
    sid    = "AllowCostExplorerAccess"
    effect = "Allow"

    actions = [
      "ce:GetCostAndUsage"
    ]

    resources = ["*"]
  }

  statement {
    sid      = "AllowGlueCatalogAccess"
    effect   = "Allow"
    
    actions  = [
       "glue:*"
    ]

    resources = ["*"]
  }

  statement {
    sid      = "AllowAthenaQuery"
    effect   = "Allow"
    
    actions  = [
       "athena:StartQueryExecution",
        "athena:GetQueryExecution",
        "athena:GetQueryResults",
        "athena:GetWorkGroup",
        "athena:StopQueryExecution"
    ]

    resources = ["*"]
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

  statement {
    sid    = "AllowS3PutGet"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:Get*",
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:*BucketPolicy",
      "s3:*PublicAccessBlock",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:PutBucketAcl",
      "s3:PutObjectAcl",
      "s3:PutBucketCORS",
      "s3:*LifecycleConfiguration",
    ]
    resources = [
      "arn:aws:s3:::${var.cost_notifier_bucket_name}",
      "arn:aws:s3:::${var.cost_notifier_bucket_name}/*",
      "arn:aws:s3:::${var.log_bucket_name}",
      "arn:aws:s3:::${var.log_bucket_name}/*",
    ]
  }

  statement {
    sid    = "AllowEventBridgeInvoke"
    effect = "Allow"

    actions = [
      "events:ListTagsForResource",
      "events:ListTargetsByRule",
      "events:DescribeRule",
      "events:PutRule",
      "events:DeleteRule",
      "events:PutTargets",
      "events:RemoveTargets",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ManageLambda"
    effect = "Allow"
    actions = [
      "lambda:ListVersionsByFunction",
      "lambda:CreateFunction",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:GetFunction",
      "lambda:DeleteFunction",
      "lambda:GetPolicy",
      "lambda:AddPermission",
      "lambda:RemovePermission",
      "lambda:GetFunctionCodeSigningConfig",
      "lambda:PutFunctionCodeSigningConfig",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "PassRoleToLambda"
    effect = "Allow"
    actions = [
      "iam:PassRole",
      "iam:GetRole",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/HaramCostNotifierLambdaRole"]
  }
}


resource "aws_iam_policy" "cost_notifier_workspace_policy" {
  name        = "HaramCostNotifierPolicy"
  description = "This policy is for haram cost notifier"
  policy      = data.aws_iam_policy_document.cost_notifier_workspace_role_policy.json
}

resource "aws_iam_role" "cost_notifier_workspace_role" {
  depends_on         = [aws_iam_policy.cost_notifier_workspace_policy]
  name               = var.cost_notifier_role_name
  assume_role_policy = data.aws_iam_policy_document.trust_relationship_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_cost_notifier_policy_to_role" {
  role       = aws_iam_role.cost_notifier_workspace_role.name
  policy_arn = aws_iam_policy.cost_notifier_workspace_policy.arn
  depends_on = [
    aws_iam_policy.cost_notifier_workspace_policy,
    aws_iam_role.cost_notifier_workspace_role
  ]
}