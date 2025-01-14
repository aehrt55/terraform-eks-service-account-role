output "roles" {
  description = "IAM roles created mapping."
  value = {
    for role_key, role in aws_iam_role.this : role_key => {
      name = role.name
      arn  = role.arn

      serviceaccount = local.role_service_accounts[role_key]
    }
  }
}
