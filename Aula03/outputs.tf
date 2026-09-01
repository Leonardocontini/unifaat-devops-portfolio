output "users" {
  description = "IAM Users criados"

  value = [
    aws_iam_user.juliana.name,
    aws_iam_user.rafael.name,
    aws_iam_user.lucas.name
  ]
}

output "groups" {
  description = "IAM Groups criados"

  value = [
    aws_iam_group.developers.name,
    aws_iam_group.platform_eng.name
  ]
}

output "policy_arns" {
  description = "ARNs das custom policies"

  value = {
    s3_read          = aws_iam_policy.s3_read.arn
    ec2_s3_full      = aws_iam_policy.ec2_s3_full.arn
    deny_destructive = aws_iam_policy.deny_destructive.arn
  }
}

output "ec2_role_arn" {
  description = "ARN da IAM Role utilizada pela EC2"

  value = aws_iam_role.ec2_role.arn
}

output "instance_profile_name" {
  description = "Nome do Instance Profile"

  value = aws_iam_instance_profile.ec2_profile.name
}