locals {
  config = {


    backends = [

      {
        github_organization = "GlueOps"
        auth_mount_path     = "glueops/github"
      },
      {
        github_organization = "glueops-rocks"
        auth_mount_path     = "github"
        tune = {
          allowed_response_headers     = []
          audit_non_hmac_request_keys  = []
          audit_non_hmac_response_keys = []
          default_lease_ttl            = "768h"
          listing_visibility           = "unauth"
          max_lease_ttl                = "768h"
          passthrough_request_headers  = []
          token_type                   = "default-service"
        }
      }
    ]
    org_team_policy_mapping = [
      {
        auth_mount_path = "glueops/github"
        github_team     = "vault_super_admins"
        policy          = <<EOT
                          path "*" {
                          capabilities = ["create", "read", "update", "delete", "list", "sudo"]
                          }
                          EOT

      },
      {
        auth_mount_path = "github"
        github_team     = "developers"
        policy          = <<EOF
                          path "secret/*" {
                            capabilities = ["create", "read", "update", "delete", "list"]
                          }

                          path "/cubbyhole/*" {
                            capabilities = ["deny"]
                          }
                          EOF
      }
    ]

  }

}
// loop through each backend in local.config.backends and create a vault_github_auth_backend resource with the organization and path specified in the map and the tune specified in the map if it exists (otherwise, use the default tune)
resource "vault_github_auth_backend" "default" {
  for_each     = { for backend in local.config.backends : backend.auth_mount_path => backend}
  organization = each.value.github_organization
  path         = each.value.auth_mount_path
  tune         = each.value.tune ? each.value.tune : {}
}


# // for each local.config.backends, create a vault_github_auth_backend resource with the organization and path specified in the map and the tune specified in the map if it exists (otherwise, use the default tune) 
# resource "vault_github_auth_backend" "default" {
#   for_each     = local.config.backends
#   organization = local.config.backends[each.key].github_organization
#   path         = local.config.backends[each.key].auth_mount_path
#   tune         = local.config.backends[each.key].tune ? local.config.backends[each.key].tune : {}
# }

resource "vault_github_team" "default" {
  for_each = local.config.org_team_policy_mapping
  backend  = vault_github_auth_backend[each.value.auth_mount_path].id
  team     = each.value.github_team
  policies = [vault_policy[each.value.github_team].name]
}

resource "vault_policy" "default" {
  for_each = local.config.org_team_policy_mapping
  name     = each.value.github_team
  policy   = each.value.policy
}






provider "vault" {
  address = jsondecode(file("../vault_access.json")).vault_address
  token   = jsondecode(file("../vault_access.json")).root_token
}



resource "vault_policy" "admin" {
  name = "admin"

  policy = <<EOF
    # Read system health check
    path "sys/health"
    {
      capabilities = ["read", "sudo"]
    }

    # Create and manage ACL policies broadly across Vault

    # List existing policies
    path "sys/policies/acl"
    {
      capabilities = ["list"]
    }

    # Create and manage ACL policies
    path "sys/policies/acl/*"
    {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # Enable and manage authentication methods broadly across Vault

    # Manage auth methods broadly across Vault
    path "auth/*"
    {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # Create, update, and delete auth methods
    path "sys/auth/*"
    {
      capabilities = ["create", "update", "delete", "sudo"]
    }

    # List auth methods
    path "sys/auth"
    {
      capabilities = ["read"]
    }

    # Enable and manage the key/value secrets engine at `secret/` path

    # List, create, update, and delete key/value secrets
    path "secret/*"
    {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # Manage secrets engines
    path "sys/mounts/*"
    {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }

    # List existing secrets engines.
    path "sys/mounts"
    {
      capabilities = ["read"]
    }

    # Disable misleading cubbyhole, the path with broad access
    path "/cubbyhole/*" {
      capabilities = ["deny"]
    }
    EOF

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
  token_policies                   = [vault_policy.read_all_env_specific_secrets.name]
}


resource "vault_policy" "read_all_env_specific_secrets" {
  name = "secrets-reader"

  policy = <<EOF
    path "secret/*" {
    capabilities = ["read"]
  }
EOF
}

resource "vault_mount" "secrets_kvv2" {
  path        = "secret/kv-v2-glueops"
  type        = "kv-v2"
  description = "KV Version 2 secrets mount"
}
 