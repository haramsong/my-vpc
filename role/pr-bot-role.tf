data "aws_iam_policy_document" "pr_bot_policy" {
  version = "2012-10-17"

  # =====================
  # Route53 (DNS)
  # =====================
  statement {
    sid    = "ManageRoute53Records"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:GetHostedZone",
      "route53:ListResourceRecordSets",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${var.route53_hosted_zone_id}"
    ]
  }

  statement {
    sid    = "GetList"
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListTagsForResource",
    ]
    resources = ["*"]
  }

  # =====================
  # ACM (Custom Domain cert)
  # =====================
  statement {
    sid    = "ManageACMCertificates"
    effect = "Allow"
    actions = [
      "acm:RequestCertificate",
      "acm:DescribeCertificate",
      "acm:DeleteCertificate",
      "acm:ListCertificates",
      "acm:ListTagsForCertificate",
      "acm:GetCertificate",
    ]
    resources = ["*"]
  }

  # =====================
  # API Gateway v2 (HTTP API)
  # =====================
  statement {
    sid    = "ManageApiGatewayV2"
    effect = "Allow"
    actions = [
      "apigateway:GET",
      "apigateway:POST",
      "apigateway:PUT",
      "apigateway:DELETE",
      "apigateway:PATCH"
    ]
    resources = ["*"]
  }

  # =====================
  # Lambda (dispatcher + step)
  # =====================
  statement {
    sid    = "ManageLambdaFunctions"
    effect = "Allow"
    actions = [
      "lambda:CreateFunction",
      "lambda:DeleteFunction",
      "lambda:GetFunction",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "lambda:ListFunctions",
      "lambda:ListVersionsByFunction",
      "lambda:AddPermission",
      "lambda:RemovePermission",
      "lambda:GetPolicy",
    ]
    resources = ["*"]
  }

  # =====================
  # IAM (Lambda Role 생성 & PassRole)
  # =====================
  statement {
    sid    = "PassLambdaExecutionRoleOnly"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/HaramPRBotLambdaRole",
    ]
  }

  # =====================
  # SSM Parameter Store
  # (GitHub webhook secret, private key)
  # =====================
  statement {
    sid    = "ManageSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:DescribeParameters"
    ]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.github_webhook_secret_name}",
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.github_private_key_name}",
    ]
  }

  # =====================
  # DynamoDB (중복 이벤트 방지용)
  # =====================
  statement {
    sid    = "ManageDynamoDBTables"
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
      "dynamodb:DescribeTable",
      "dynamodb:UpdateTable",
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:ListTagsOfResource"
    ]
    resources = ["*"]
  }

  # =====================
  # CloudWatch Logs
  # =====================
  statement {
    sid    = "ManageCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "pr_bot_workspace_policy" {
  name        = "HaramPRBotPolicy"
  description = "This policy is for haram github pr bot"
  policy      = data.aws_iam_policy_document.pr_bot_policy.json
}

resource "aws_iam_role" "pr_bot_workspace_role" {
  depends_on         = [aws_iam_policy.pr_bot_workspace_policy]
  name               = var.pr_bot_role_name
  assume_role_policy = data.aws_iam_policy_document.trust_relationship_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_pr_bot_policy_to_role" {
  role       = aws_iam_role.pr_bot_workspace_role.name
  policy_arn = aws_iam_policy.pr_bot_workspace_policy.arn
  depends_on = [
    aws_iam_policy.pr_bot_workspace_policy,
    aws_iam_role.pr_bot_workspace_role
  ]
}