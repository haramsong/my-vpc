output "assume_vpc_role_arn" {
  sensitive  = true
  value      = aws_iam_role.vpc_workspace_role.arn
  depends_on = [aws_iam_role.vpc_workspace_role]
}

output "assume_cost_notifier_role_arn" {
  sensitive  = true
  value      = aws_iam_role.cost_notifier_workspace_role.arn
  depends_on = [aws_iam_role.cost_notifier_workspace_role]
}


