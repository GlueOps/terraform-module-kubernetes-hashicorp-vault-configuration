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
  default_role       = "reader"

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

# A second auth mount for the CLI, so its roles can keep the same names as the
# policies they grant. Role names are unique per mount, and reader/editor on the
# oidc mount are already taken by the browser-flow roles the web UI logs in
# through - sharing the mount would have meant mangled names like "reader-jwt",
# leaking an implementation detail into what operators type.
#
# type "jwt" validates a token that is presented directly, with no redirect flow,
# so it needs no client credentials - only somewhere to fetch Dex's public keys.
resource "vault_jwt_auth_backend" "cli" {
  path               = "jwt"
  type               = "jwt"
  oidc_discovery_url = "https://dex.${var.captain_domain}"
  bound_issuer       = "https://dex.${var.captain_domain}"
  description        = "Token-based authentication for CLI clients"

  # No listing_visibility here, unlike the oidc mount: this one must NOT appear on
  # the unauthenticated web UI login page. A browser user who picks it is prompted
  # for a role name and a raw JWT, which is not something they have -- the mount
  # exists for CLIs that POST a token to /v1/auth/jwt/login. Omitting it also stops
  # auth/jwt being anonymously enumerable through sys/internal/ui/mounts.
  tune {
    token_type        = "default-service"
    max_lease_ttl     = "768h"
    default_lease_ttl = "768h"
  }
}

# CLI counterparts of the oidc roles above. Those drive the browser flow and are
# what the web UI uses; these accept a Dex id_token posted straight to
# auth/jwt/login, so the CLI needs no browser, no loopback listener and no
# redirect URI - which is what makes it work from a machine whose browser lives
# somewhere else. Same group bindings and same policy: only the way the identity
# is presented differs.
resource "vault_jwt_auth_backend_role" "cli" {
  for_each = { for idx, mapping in var.org_team_policy_mappings : idx => mapping }

  backend    = vault_jwt_auth_backend.cli.path
  role_name  = each.value.policy_name
  role_type  = "jwt"
  user_claim = "email"

  # "toolbox" is the public Dex client developers mint edge tokens from
  # (defined in platform-helm-chart-platform); the same token authenticates here.
  bound_audiences = ["toolbox"]

  bound_claims = {
    "groups" = join(",", each.value.oidc_groups)
  }
  token_policies = [each.value.policy_name]

  # Bound to the life of the Dex id_token that attested the identity, rather than
  # inheriting the mount's 768h default. The OpenBao token is opaque, so unlike a
  # Dex-issued JWT it is NOT invalidated by restarting Dex -- an operator's only
  # fast kill switch. Left at the default it would outlive the identity behind it
  # by a month, off-edge, for anyone who obtained ~/.vault-token. Re-login is
  # transparent to the CLI, so a short TTL costs nothing.
  token_ttl     = 86400 # 24h
  token_max_ttl = 86400 # 24h
}


data "aws_s3_object" "vault_access" {
  bucket = var.aws_s3_bucket_name
  key    = var.aws_s3_key_vault_secret_file
}


provider "vault" {
  address = "https://127.0.0.1:8200"
  token   = jsondecode(data.aws_s3_object.vault_access.body).root_token
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
