
data "aws_iam_policy_document" "blog_workspace_role_policy" {
  version = "2012-10-17"
  statement {
    sid    = "AllowS3FullAccessToBucket"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy",
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock",
      "s3:DeleteBucketPublicAccessBlock",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetBucketAcl",
      "s3:PutBucketAcl",
      "s3:GetObjectAcl",
      "s3:PutObjectAcl",
    ]
    resources = [
      "arn:aws:s3:::${var.blog_bucket_name}",
      "arn:aws:s3:::${var.blog_bucket_name}/*",
    ]
  }

  statement {
    sid    = "AllowCloudFrontFullAccess"
    effect = "Allow"
    actions = [
      "cloudfront:CreateDistribution",
      "cloudfront:DeleteDistribution",
      "cloudfront:GetDistribution",
      "cloudfront:UpdateDistribution",
      "cloudfront:ListDistributions",
      "cloudfront:CreateCachePolicy",
      "cloudfront:DeleteCachePolicy",
      "cloudfront:GetCachePolicy",
      "cloudfront:UpdateCachePolicy",
      "cloudfront:ListCachePolicies",
      "cloudfront:CreateOriginAccessControl",
      "cloudfront:DeleteOriginAccessControl",
      "cloudfront:GetOriginAccessControl",
      "cloudfront:UpdateOriginAccessControl",
      "cloudfront:ListOriginAccessControls",
      "cloudfront:DescribeFunction",
      "cloudfront:CreateFunction",
      "cloudfront:DeleteFunction",
      "cloudfront:GetFunction",
      "cloudfront:UpdateFunction",
      "cloudfront:PublishFunction",
      "cloudfront:ListFunctions",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowRoute53FullAccessToRecord"
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:GetHostedZone",
      "route53:ListResourceRecordSets",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${var.route53_hosted_zone_id}",
    ]
  }

  statement {
    sid    = "GetList"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "route53:ListHostedZones",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "blog_workspace_policy" {
  name        = "HaramBlogPolicy"
  description = "This policy is for haram blog"
  policy      = data.aws_iam_policy_document.blog_workspace_role_policy.json
}

resource "aws_iam_role" "blog_workspace_role" {
  depends_on         = [aws_iam_policy.blog_workspace_policy]
  name               = var.blog_role_name
  assume_role_policy = data.aws_iam_policy_document.trust_relationship_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_blog_policy_to_role" {
  role       = aws_iam_role.blog_workspace_role.name
  policy_arn = aws_iam_policy.blog_workspace_policy.arn
  depends_on = [
    aws_iam_policy.blog_workspace_policy,
    aws_iam_role.blog_workspace_role
  ]
}