variable "github_base_url" {
  type        = string
  description = "This is the target GitHub base API endpoint. Providing a value is a requirement when working with GitHub Enterprise. It is optional to provide this value and it can also be sourced from the `GITHUB_BASE_URL` environment variable. The value must end with a slash, for example: `https://terraformtesting-ghe.westus.cloudapp.azure.com/`"
  default     = null
}

# Personal Access Token (PAT) Authentication Variables
variable "ssm_github_api_key" {
  type        = string
  description = "SSM path to the GitHub API key"
  default     = "/argocd/github/api_key"
}

variable "github_token_override" {
  type        = string
  description = "Use the value of this variable as the GitHub token instead of reading it from SSM"
  default     = null
}

locals {
  github_token = local.create_github_webhook ? (
    var.github_app_enabled ? null : coalesce(var.github_token_override, try(data.aws_ssm_parameter.github_api_key[0].value, null))
  ) : ""
}

# SSM Parameter for PAT Authentication
data "aws_ssm_parameter" "github_api_key" {
  count           = local.create_github_webhook && !var.github_app_enabled ? 1 : 0
  name            = var.ssm_github_api_key
  with_decryption = true
}

# SSM Parameter for GitHub App Authentication
data "aws_ssm_parameter" "github_app_private_key" {
  count           = local.create_github_webhook && var.github_app_enabled ? 1 : 0
  name            = var.ssm_github_app_private_key
  with_decryption = true
}

# We will only need the github provider if we are creating the GitHub webhook with github_repository_webhook.
provider "github" {
  base_url = local.create_github_webhook ? var.github_base_url : null
  owner    = local.create_github_webhook ? var.github_organization : null
  token    = local.create_github_webhook ? local.github_token : null

  dynamic "app_auth" {
    for_each = local.create_github_webhook && var.github_app_enabled ? [1] : []
    content {
      id              = var.github_app_id
      installation_id = var.github_app_installation_id
      pem_file        = data.aws_ssm_parameter.github_app_private_key[0].value
    }
  }
}
