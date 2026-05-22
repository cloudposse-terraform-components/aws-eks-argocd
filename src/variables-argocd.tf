# ArgoCD variables

variable "alb_group_name" {
  type        = string
  description = "A name used in annotations to reuse an ALB (e.g. `argocd`) or to generate a new one"
  default     = null
}

variable "alb_name" {
  type        = string
  description = "The name of the ALB (e.g. `argocd`) provisioned by `alb-controller`. Works together with `var.alb_group_name`"
  default     = null
}

variable "alb_logs_bucket" {
  type        = string
  description = "The name of the bucket for ALB access logs. The bucket must have policy allowing the ELB logging principal"
  default     = ""
}

variable "alb_logs_prefix" {
  type        = string
  description = "`alb_logs_bucket` s3 bucket prefix"
  default     = ""
}

variable "certificate_issuer" {
  type        = string
  description = "Certificate manager cluster issuer"
  default     = "letsencrypt-staging"
}

variable "argocd_create_namespaces" {
  type        = bool
  description = "ArgoCD create namespaces policy"
  default     = false
}

variable "argocd_repositories" {
  type = map(object({
    environment = string # The environment where the `argocd_repo` component is deployed.
    stage       = string # The stage where the `argocd_repo` component is deployed.
    tenant      = string # The tenant where the `argocd_repo` component is deployed.
  }))
  description = "Map of objects defining an `argocd_repo` to configure.  The key is the name of the ArgoCD repository."
  default     = {}
}

variable "github_organization" {
  type        = string
  description = "GitHub Organization"
}

variable "ssm_store_account" {
  type        = string
  description = "Account storing SSM parameters"
}

variable "ssm_store_account_tenant" {
  type        = string
  description = <<-EOT
  Tenant of the account storing SSM parameters.

  If the tenant label is not used, leave this as null.
  EOT
  default     = null
}

variable "ssm_store_account_region" {
  type        = string
  description = "AWS region storing SSM parameters"
}

variable "ssm_oidc_client_id" {
  type        = string
  description = "The SSM Parameter Store path for the ID of the IdP client"
  default     = "/argocd/oidc/client_id"
}

variable "ssm_oidc_client_secret" {
  type        = string
  description = "The SSM Parameter Store path for the secret of the IdP client"
  default     = "/argocd/oidc/client_secret"
}

variable "host" {
  type        = string
  description = "Host name to use for ingress and ALB"
  default     = ""
}

variable "forecastle_enabled" {
  type        = bool
  description = "Toggles Forecastle integration in the deployed chart"
  default     = false
}

variable "admin_enabled" {
  type        = bool
  description = "Toggles Admin user creation the deployed chart"
  default     = false
}

variable "anonymous_enabled" {
  type        = bool
  description = "Toggles anonymous user access using default RBAC setting (Defaults to read-only)"
  default     = false
}

variable "oidc_enabled" {
  type        = bool
  description = "Toggles OIDC integration in the deployed chart"
  default     = false
}

variable "oidc_issuer" {
  type        = string
  description = "OIDC issuer URL"
  default     = ""
}

variable "oidc_name" {
  type        = string
  description = "Name of the OIDC resource"
  default     = ""
}

variable "oidc_rbac_scopes" {
  type        = string
  description = "OIDC RBAC scopes to request"
  default     = "[argocd_realm_access]"
}

variable "oidc_requested_scopes" {
  type        = string
  description = "Set of OIDC scopes to request"
  default     = "[\"openid\", \"profile\", \"email\", \"groups\"]"
}

variable "saml_enabled" {
  type        = bool
  description = "Toggles SAML integration in the deployed chart"
  default     = false
}

variable "saml_rbac_scopes" {
  type        = string
  description = "SAML RBAC scopes to request"
  default     = "[email,groups]"
}

variable "service_type" {
  type        = string
  default     = "NodePort"
  description = <<-EOT
  Service type for exposing the ArgoCD service. The available type values and their behaviors are:
    ClusterIP: Exposes the Service on a cluster-internal IP. Choosing this value makes the Service only reachable from within the cluster.
    NodePort: Exposes the Service on each Node's IP at a static port (the NodePort).
    LoadBalancer: Exposes the Service externally using a cloud provider's load balancer.
  EOT
}

variable "argocd_rbac_policies" {
  type        = list(string)
  default     = []
  description = <<-EOT
  List of ArgoCD RBAC Permission strings to be added to the argocd-rbac configmap policy.csv item.

  See https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/ for more information.
  EOT
}

variable "argocd_rbac_default_policy" {
  type        = string
  default     = "role:readonly"
  description = <<-EOT
  Default ArgoCD RBAC default role.

  See https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/#basic-built-in-roles for more information.
  EOT
}

variable "argocd_rbac_groups" {
  type = list(object({
    group = string,
    role  = string
  }))
  default     = []
  description = <<-EOT
  List of ArgoCD Group Role Assignment strings to be added to the argocd-rbac configmap policy.csv item.
  e.g.
  [
    {
      group: idp-group-name,
      role: argocd-role-name
    },
  ]
  becomes: `g, idp-group-name, role:argocd-role-name`
  See https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/ for more information.
  EOT
}

variable "eks_component_name" {
  type        = string
  default     = "eks/cluster"
  description = "The name of the eks component"
}

variable "saml_sso_providers" {
  type = map(object({
    component   = string
    environment = optional(string, null)
  }))

  default     = {}
  description = "SAML SSO providers components"
}

variable "github_deploy_keys_enabled" {
  type        = bool
  default     = true
  description = <<-EOT
  Enable GitHub deploy keys for the repository. These are used for Argo CD application syncing.

  Alternatively, you can use a GitHub App to access this desired state repository configured with `var.github_app_enabled`, `var.github_app_id`, and `var.github_app_installation_id`.
  EOT
}

variable "alb_scheme" {
  type        = string
  default     = "internet-facing"
  description = <<-EOT
  Scheme of the ALB fronting the argocd-server Ingress. One of `internet-facing` or `internal`.

  Use `internal` when argocd should only be reachable from inside the VPC (e.g. via VPN or
  a private connectivity mesh). When combined with `var.webhook_ingress_enabled`, the
  primary UI/API moves internal while `/api/webhook` stays reachable on a separate Ingress.
  EOT

  validation {
    condition     = contains(["internet-facing", "internal"], var.alb_scheme)
    error_message = "alb_scheme must be \"internet-facing\" or \"internal\"."
  }
}

variable "webhook_ingress_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
  Provision a second, path-restricted Ingress exposing only `/api/webhook` on a separate
  ALB and hostname.

  Intended use: when `var.alb_scheme` is `internal` (argocd UI on a private ALB), GitHub
  push webhooks can't reach the cluster. Enabling this creates a minimal public Ingress
  matching only `Host: <var.webhook_host>` AND `Path: /api/webhook`, so the GitHub webhook
  endpoint stays reachable while the rest of the API/UI does not.

  The component's GitHub webhook resource (`github_repository_webhook.default`) automatically
  retargets to the new hostname when this is `true`.
  EOT
}

variable "webhook_alb_group_name" {
  type        = string
  default     = null
  description = "ALB group name annotation for the webhook-only Ingress. Typically the existing internet-facing ingress group. Required when `var.webhook_ingress_enabled` is `true`."
}

variable "webhook_alb_scheme" {
  type        = string
  default     = "internet-facing"
  description = "Scheme for the webhook-only Ingress's ALB. Almost always `internet-facing` (the whole point is to expose `/api/webhook` to GitHub)."

  validation {
    condition     = contains(["internet-facing", "internal"], var.webhook_alb_scheme)
    error_message = "webhook_alb_scheme must be \"internet-facing\" or \"internal\"."
  }
}

variable "webhook_host" {
  type        = string
  default     = null
  description = <<-EOT
  FQDN for the webhook-only Ingress. If `null` (default) and `var.webhook_ingress_enabled`
  is `true`, falls back to `argocd-webhook.<var.host or generated host>`.

  Must resolve to the ALB selected by `var.webhook_alb_group_name`, and the ALB's listener
  must have a TLS certificate that covers this hostname.
  EOT
}
