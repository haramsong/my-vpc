output "assume_vpc_role_arn" {
  sensitive  = true
  value      = aws_iam_role.vpc_workspace_role.arn
  depends_on = [aws_iam_role.vpc_workspace_role]
}

