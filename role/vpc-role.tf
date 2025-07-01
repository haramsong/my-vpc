
data "aws_iam_policy_document" "vpc_workspace_role_policy" {
  version = "2012-10-17"
  statement {
    sid    = "NetworkManagementPolicy"
    effect = "Allow"
    actions = [
      "ec2:*SecurityGroup*",
      "ec2:*Subnet*",
      "ec2:*InternetGateway*",
      "ec2:*Vpc",
      "ec2:*VpcAssociations",
      "ec2:*VpcAttribute",
      "ec2:*VpcBlockPublicAccess*",
      "ec2:*RouteTable",
      "ec2:DescribeRouteTables",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeVpcs",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "vpc_workspace_policy" {
  name        = "HaramVPCPolicy"
  description = "This policy is for haram vpc"
  policy      = data.aws_iam_policy_document.vpc_workspace_role_policy.json
}

resource "aws_iam_role" "vpc_workspace_role" {
  depends_on         = [aws_iam_policy.vpc_workspace_policy]
  name               = var.vpc_role_name
  assume_role_policy = data.aws_iam_policy_document.trust_relationship_policy.json
}

resource "aws_iam_role_policy_attachment" "attach_vpc_policy_to_role" {
  role       = aws_iam_role.vpc_workspace_role.name
  policy_arn = aws_iam_policy.vpc_workspace_policy.arn
  depends_on = [
    aws_iam_policy.vpc_workspace_policy,
    aws_iam_role.vpc_workspace_role
  ]
}