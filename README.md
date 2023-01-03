# terraform-module-kubernetes-hashicorp-vault-configuration



This Terraform module configures vault for kvv2 usage. This repo should be used in the context of deploying with an [admiral](https://github.com/glueops/admiral) and after you have [initialized](https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-initialization) the vault cluster

## Prerequisites

Assume you have just deployed https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-initialization and still have the SSL cert in a environment variable and connection to vault running via `kubectl port-forward`

### Example of the configurations expected by this module:

Example:
```
  vault_configurations = {
    backends = [
      {
        github_organization = "GlueOps"
        auth_mount_path     = "glueops/github"
        tune = [{
          allowed_response_headers     = []
          audit_non_hmac_request_keys  = []
          audit_non_hmac_response_keys = []
          default_lease_ttl            = "768h"
          listing_visibility           = "hidden"
          max_lease_ttl                = "768h"
          passthrough_request_headers  = []
          token_type                   = "default-service"
        }]
      },
      {
        github_organization = "glueops-rocks"
        auth_mount_path     = "github"
        tune = [{
          allowed_response_headers     = []
          audit_non_hmac_request_keys  = []
          audit_non_hmac_response_keys = []
          default_lease_ttl            = "768h"
          listing_visibility           = "unauth"
          max_lease_ttl                = "768h"
          passthrough_request_headers  = []
          token_type                   = "default-service"
        }]
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

```
