locals {
  critical_event_names = [
    # IAM
    "CreateUser",
    "DeleteUser",
    "UpdateUser",
    "CreateAccessKey",
    "DeleteAccessKey",
    "AttachUserPolicy",
    "DetachUserPolicy",
    "PutUserPolicy",
    "AttachRolePolicy",
    "DetachRolePolicy",
    "CreateRole",
    "UpdateRole",
    "DeleteRole",
    "CreatePolicy",
    "DeletePolicy",
    "UpdatePolicy",
    "AddUserToGroup",
    "RemoveUserFromGroup",
    "UpdateRolePolicy",
    "CreateLoginProfile",
    "UpdateLoginProfile",
    "ResetServiceSpecificCredential",

    # S3
    "CreateBucket",
    "DeleteBucket",
    "PutBucketPolicy",
    "DeleteBucketPolicy",
    "PutObject",
    "DeleteObject",

    # EC2
    "RunInstances",
    "TerminateInstances",
    "StartInstances",
    "StopInstances",
    "ModifyInstanceAttribute",

    # RDS
    "CreateDBInstance",
    "DeleteDBInstance",
    "ModifyDBInstance",

    # Lambda
    "CreateFunction",
    "DeleteFunction",
    "UpdateFunctionCode",
    "UpdateFunctionConfiguration",

    # CloudTrail
    "CreateTrail",
    "DeleteTrail",
    "UpdateTrail",

    # KMS
    "CreateKey",
    "ScheduleKeyDeletion",
    "CancelKeyDeletion",
    "PutKeyPolicy",

    # DynamoDB
    "CreateTable",
    "DeleteTable",
    "UpdateTable",

    # EKS/ECS
    "CreateCluster",
    "DeleteCluster",
    "RunTask",
    "StartTask",

    # VPC/SG
    "CreateSecurityGroup",
    "AuthorizeSecurityGroupIngress",
    "AuthorizeSecurityGroupEgress",
    "ModifyVpcEndpoint",
  ]

  critical_service_sources = [
    "aws.iam",
    "aws.s3",
    "aws.ec2",
    "aws.rds",
    "aws.lambda",
    "aws.cloudtrail",
    "aws.kms",
    "aws.dynamodb",
    "aws.ecs",
    "aws.eks",
  ]

  critical_event_pattern = {
    source        = local.critical_service_sources
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = local.critical_event_names
    }
  }
}

resource "aws_cloudwatch_event_rule" "critical_security_events" {
  name        = "critical-security-event-rule"
  description = "Detect critical unauthorized activity"

  event_pattern = jsonencode(local.critical_event_pattern)
}

resource "aws_cloudwatch_event_target" "send_to_lambda" {
  rule      = aws_cloudwatch_event_rule.critical_security_events.name
  target_id = "lambdaTarget"
  arn       = aws_lambda_function.alert_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.critical_security_events.arn
}