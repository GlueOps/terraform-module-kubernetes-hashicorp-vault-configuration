variable "org_team_policy_mappings" {
  type = list(object({
    policy_name = string
    oidc_groups = list(string)
  }))
  description = "Each OIDC group should be in the format of GITHUB_ORG_NAME:GITHUB_TEAM_NAME and the policy name should be either 'reader' or 'editor'"
  default = [
    {
      policy_name = "reader"
      oidc_groups = ["example-org:team1", "example-org:team2"]
    },
    {
      policy_name = "editor"
      oidc_groups = ["example-org:team1", "example-org:team3"]
    }
  ]
}

variable "captain_domain" {
  type        = string
  description = "Captain Domain for the cluster"
  nullable    = false
}

variable "oidc_client_secret" {
  type        = string
  description = "This is the dex client secret for the 'vault' ClientID"
  nullable    = false
}

resource "vault_jwt_auth_backend" "default" {
  oidc_discovery_url = "https://dex.${var.captain_domain}"
  oidc_client_id     = "vault"
  oidc_client_secret = var.oidc_client_secret
  bound_issuer       = "https://dex.${var.captain_domain}"
  description        = "Vault authentication method OIDC"
  path               = "oidc"
  type               = "oidc"

  tune {
    listing_visibility = "unauth"
    token_type         = "default-service"
    max_lease_ttl      = "768h"
    default_lease_ttl  = "768h"
  }
}

resource "vault_jwt_auth_backend_role" "default" {
  for_each = { for idx, mapping in var.org_team_policy_mappings : idx => mapping }

  backend     = vault_jwt_auth_backend.default.path
  role_name   = each.value.policy_name
  role_type   = "oidc"
  user_claim  = "email"
  oidc_scopes = ["openid", "profile", "email", "groups"]

  bound_claims = {
    "groups" = join(",", each.value.oidc_groups) # Join the groups using a comma (or another delimiter of your choice)
  }
  token_policies        = [each.value.policy_name]
  allowed_redirect_uris = ["https://vault.${var.captain_domain}/ui/vault/auth/oidc/oidc/callback"] # Replace with your Vault instance's callback URL
}


data "aws_s3_bucket_object" "vault_access" {
  bucket = var.aws_s3_bucket_name
  key    = var.aws_s3_key_vault_secret_file
}


provider "vault" {
  address = "https://127.0.0.1:8200"
  token   = jsondecode(data.aws_s3_bucket_object.vault_access.body).root_token
}







resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}



resource "vault_kubernetes_auth_backend_config" "config" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://kubernetes.default.svc.cluster.local:443"
}



resource "vault_kubernetes_auth_backend_role" "env_roles" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "reader-role"
  bound_service_account_names      = ["*"]
  bound_service_account_namespaces = ["*"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.reader.name]
}

resource "vault_mount" "secrets_kvv2" {
  path        = "secret"
  type        = "kv-v2"
  description = "KV Version 2 secrets mount"
}


resource "vault_kubernetes_auth_backend_role" "vault_backup" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vault-backup-role"
  bound_service_account_names      = ["vault-backup"]
  bound_service_account_namespaces = ["glueops-core-backup"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.vault_backup.name]
}
