data "aws_iam_policy_document" "security_alarm_workspace_policy" {
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
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/HaramEventBridgeLambdaRole"]
  }
}


resource "aws_iam_policy" "security_alarm_workspace_policy" {
  name        = "HaramSecurityAlarmPolicy"
  description = "This policy is for haram security alarm"
  policy      = data.aws_iam_policy_document.security_alarm_workspace_policy.json
}

resource "aws_iam_role" "security_alarm_workspace_role" {
  depends_on         = [aws_iam_policy.security_alarm_workspace_policy]
  name               = var.security_alarm_role_name
  assume_role_policy = data.aws_iam_policy_document.trust_relationship_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_security_alarm_policy_to_role" {
  role       = aws_iam_role.security_alarm_workspace_role.name
  policy_arn = aws_iam_policy.security_alarm_workspace_policy.arn
  depends_on = [
    aws_iam_policy.security_alarm_workspace_policy,
    aws_iam_role.security_alarm_workspace_role
  ]
}