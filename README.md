<!-- BEGIN_TF_DOCS -->
# terraform-module-kubernetes-hashicorp-vault-configuration

This Terraform module configures vault for kvv2 usage. This repo should be used in the context of deploying with an [admiral](https://github.com/glueops/admiral) and after you have [initialized](https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-initialization) the vault cluster

## Prerequisites

Assume you have just deployed <https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-initialization> and still have the SSL cert in a environment variable and connection to vault running via `kubectl port-forward`

### Example of the configurations expected by this module

```hcl
vault_configurations = {
  oidc_client_secret = "yolo1234"
  captain_domain     = "test-30-np.venkata.onglueops.rocks"
  org_team_policy_mappings = [
    {
      oidc_groups = ["GlueOps:vault_super_admins"]
      policy_name = "editor"
    },
    {
      oidc_groups = ["GlueOps:vault_super_admins", "glueops-rocks:developers"]
      policy_name = "reader"
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | 3.14.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_vault"></a> [vault](#provider\_vault) | 3.14.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [vault_auth_backend.kubernetes](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/auth_backend) | resource |
| [vault_github_auth_backend.default](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/github_auth_backend) | resource |
| [vault_github_team.default](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/github_team) | resource |
| [vault_kubernetes_auth_backend_config.config](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/kubernetes_auth_backend_config) | resource |
| [vault_kubernetes_auth_backend_role.env_roles](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_kubernetes_auth_backend_role.vault_backup](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_mount.secrets_kvv2](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/mount) | resource |
| [vault_policy.admin](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/policy) | resource |
| [vault_policy.default](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/policy) | resource |
| [vault_policy.read_all_env_specific_secrets](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/policy) | resource |
| [vault_policy.vault_backup](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_backends"></a> [backends](#input\_backends) | n/a | <pre>list(object({<br>    github_organization = string<br>    auth_mount_path     = string<br>    tune = list(object({<br>      allowed_response_headers     = list(string)<br>      audit_non_hmac_request_keys  = list(string)<br>      audit_non_hmac_response_keys = list(string)<br>      default_lease_ttl            = string<br>      listing_visibility           = string<br>      max_lease_ttl                = string<br>      passthrough_request_headers  = list(string)<br>      token_type                   = string<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_org_team_policy_mapping"></a> [org\_team\_policy\_mapping](#input\_org\_team\_policy\_mapping) | n/a | <pre>list(object({<br>    auth_mount_path = string<br>    github_team     = string<br>    policy          = string<br>  }))</pre> | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
