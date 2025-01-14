data "aws_caller_identity" "current" {}

locals {
  role_service_accounts = {
    for role_key, role in var.roles : role_key => "${replace(role_key, "_", "-")}${var.service_account_name_postfix}"
  }
  role_policy_attachments = flatten([
    for role_key, role in var.roles : [
      for policy_key, policy in role.policies : {
        role_key   = role_key
        policy_key = policy_key
        policy_arn = policy.arn
      }
    ]
  ])
}

data "aws_iam_policy_document" "eks_assume_role_policy" {
  for_each = var.roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${var.eks_oidc_provider_name}"]
      type        = "Federated"
    }

    condition {
      test     = "StringEquals"
      variable = "${var.eks_oidc_provider_name}:sub"
      values   = ["system:serviceaccount:${var.k8s_namespace}:${local.role_service_accounts[each.key]}"]
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = data.aws_iam_policy_document.eks_assume_role_policy

  name = var.roles[each.key].name
  tags = var.roles[each.key].tags

  assume_role_policy = each.value.json
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = {
    for attachment in local.role_policy_attachments : "${attachment.role_key}:${attachment.policy_key}" => attachment
  }

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}
