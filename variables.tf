variable "eks_oidc_provider_name" {
  type = string
}

variable "k8s_namespace" {
  type        = string
  description = "The namespace for the eks resource."
}

variable "roles" {
  default = {}
  type = map(object({
    name = string
    tags = object({})
    policies = map(object({
      arn = string
    }))
  }))
}

variable "service_account_name_postfix" {
  default = "-service-account"
  type    = string
}
