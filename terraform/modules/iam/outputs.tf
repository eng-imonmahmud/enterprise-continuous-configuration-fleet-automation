output "instance_profile_name" {
  value = aws_iam_instance_profile.ssm_profile.name
}

output "role_name" {
  value = aws_iam_role.ssm_role.name
}
