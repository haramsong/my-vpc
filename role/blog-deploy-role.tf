data "aws_iam_policy_document" "blog_deploy_workspace_role_policy" {

  statement {
    sid       = "ListAllMyBuckets"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    sid       = "SettingBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.blog_bucket_name}"]
  }

  statement {
    sid    = "SettingBucketObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = ["arn:aws:s3:::${var.blog_bucket_name}/*"]
  }

  statement {
    sid    = "GetParameter"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters",
    ]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/*",
    ]
  }

  statement {
    sid    = "CreateInvalidation"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetInvalidation",
      "cloudfront:ListInvalidations",
      "cloudfront:GetDistribution",
      "cloudfront:ListDistributions",
    ]
    resources = [
      "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${var.cdn_id}",
      "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:invalidation/*",
    ]
  }
}


resource "aws_iam_policy" "blog_deploy_workspace_policy" {
  name        = "HaramBlogDeployPolicy"
  description = "This policy is for haram blog deployments"
  policy      = data.aws_iam_policy_document.blog_deploy_workspace_role_policy.json
}

resource "aws_iam_role" "blog_deploy_workspace_role" {
  depends_on         = [aws_iam_policy.blog_deploy_workspace_policy]
  name               = var.blog_deploy_role_name
  assume_role_policy = data.aws_iam_policy_document.trust_relationship_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_blog_deploy_policy_to_role" {
  role       = aws_iam_role.blog_deploy_workspace_role.name
  policy_arn = aws_iam_policy.blog_deploy_workspace_policy.arn
  depends_on = [
    aws_iam_policy.blog_deploy_workspace_policy,
    aws_iam_role.blog_deploy_workspace_role
  ]
}
