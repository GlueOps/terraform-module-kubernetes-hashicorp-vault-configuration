
variable "backends" {
  type = list(object({
    github_organization = string
    auth_mount_path     = string
    tune = list(object({
      allowed_response_headers     = list(string)
      audit_non_hmac_request_keys  = list(string)
      audit_non_hmac_response_keys = list(string)
      default_lease_ttl            = string
      listing_visibility           = string
      max_lease_ttl                = string
      passthrough_request_headers  = list(string)
      token_type                   = string
    }))
  }))
}

variable "org_team_policy_mapping" {
  type = list(object({
    auth_mount_path = string
    github_team     = string
    policy          = string
  }))
}



resource "vault_github_auth_backend" "default" {
  for_each     = { for backend in var.backends : backend.auth_mount_path => backend }
  organization = each.value.github_organization
  path         = each.value.auth_mount_path
  tune         = each.value.tune
}

resource "vault_github_team" "default" {
  for_each = { for mapping in var.org_team_policy_mapping : mapping.github_team => mapping }
  backend  = vault_github_auth_backend.default[each.value.auth_mount_path].path
  team     = each.value.github_team
  policies = [vault_policy.default[each.value.github_team].name]
}

resource "vault_policy" "default" {
  for_each = { for mapping in var.org_team_policy_mapping : mapping.github_team => mapping }
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


resource "vault_kubernetes_auth_backend_role" "vault_backup" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "vault-backup-role"
  bound_service_account_names      = ["vault-backup"]
  bound_service_account_namespaces = ["glueops-core-backup"]
  token_ttl                        = 3600
  token_policies                   = [vault_policy.vault_backup.name]
}

resource "vault_policy" "vault_backup" {
  name = "vault-backup"

  policy = <<EOF
    path "sys/storage/raft/snapshot" {
    capabilities = ["read"]
  }
EOF
}
