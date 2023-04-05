resource "vault_policy" "editor" {
  name   = "reader_and_writer"
  policy = <<EOF
                        path "secret/*" {
                          capabilities = ["create", "read", "update", "delete", "list"]
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

resource "vault_policy" "read_all_env_specific_secrets" {
  name = "reader"

  policy = <<EOF
    path "secret/*" {
    capabilities = ["read"]
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
