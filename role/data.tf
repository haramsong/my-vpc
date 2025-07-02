data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "trust_relationship_policy" {
  version = "2012-10-17"
  statement {
    sid    = "AllowGithubActionAndLocalToAssumeRole"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.assume_role_name}",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/admin"
      ]
    }
  }
}