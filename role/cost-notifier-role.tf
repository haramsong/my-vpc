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
    sid    = "AllowEventBridgeInvoke"
    effect = "Allow"

    actions = [
      "events:PutRule",
      "events:PutTargets",
      "events:DescribeRule"
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