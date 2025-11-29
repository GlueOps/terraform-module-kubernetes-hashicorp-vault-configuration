resource "vault_policy" "editor" {
  name   = "editor"
  policy = <<EOF
    path "secret/*" {
      capabilities = ["create", "read", "update", "delete", "list"]
    }

    # Service account token creation (restricted to reader/editor policies only)
    path "auth/token/create/service-account" {
      capabilities = ["create", "update"]
    }

    # Can read the service-account role definition
    path "auth/token/roles/service-account" {
      capabilities = ["read"]
    }

    # Can list available token roles
    path "auth/token/roles" {
      capabilities = ["list"]
    }

    # List token accessors (to view all tokens)
    path "auth/token/accessors" {
      capabilities = ["list", "sudo"]
    }

    # Lookup tokens by accessor
    path "auth/token/lookup-accessor" {
      capabilities = ["update"]
    }

    # Revoke tokens by accessor
    path "auth/token/revoke-accessor" {
      capabilities = ["update"]
    }

    # Renew tokens by accessor
    path "auth/token/renew-accessor" {
      capabilities = ["update"]
    }

    # Self-service token management
    path "auth/token/renew-self" {
      capabilities = ["update"]
    }
    
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }
    
    path "auth/token/revoke-self" {
      capabilities = ["update"]
    }

    path "/cubbyhole/*" {
      capabilities = ["deny"]
    }
    EOF
}

resource "vault_policy" "super_admin" {
  name   = "super_admin"
  policy = <<EOF
    path "*" {
      capabilities = ["create", "read", "update", "delete", "list", "sudo"]
    }
    EOF
}

resource "vault_policy" "reader" {
  name = "reader"

  policy = <<EOF
    path "secret/*" {
    capabilities = ["read", "list"]
    }
    
    # Self-service token management
    path "auth/token/renew-self" {
      capabilities = ["update"]
    }
    
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }
    
    path "auth/token/revoke-self" {
      capabilities = ["update"]
    }

    path "/cubbyhole/*" {
      capabilities = ["deny"]
    }
    EOF
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


resource "vault_policy" "vault_backup" {
  name = "vault-backup"

  policy = <<EOF
    path "sys/storage/raft/snapshot" {
    capabilities = ["read"]
  }
EOF
}

# Service account token role - restricted to reader/editor policies only
# This allows editors to create renewable service account tokens without privilege escalation risk
resource "vault_token_auth_backend_role" "service_account" {
  role_name              = "service-account"
  
  # SECURITY: Can ONLY create tokens with reader or editor policies
  allowed_policies       = ["reader", "editor"]
  
  # Token security settings
  orphan                 = true    # Service tokens survive parent (OIDC) token expiration
  renewable              = true
  token_explicit_max_ttl = 7776000 # 90 days in seconds (absolute maximum lifetime)
}
