<!-- BEGIN_TF_DOCS -->
# terraform-module-kubernetes-hashicorp-vault-configuration

This Terraform module configures vault for kvv2 usage. This repo should be used in the context of deploying with an [admiral](https://github.com/glueops/admiral) and after you have [initialized](https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-initialization) the vault cluster

## Prerequisites

Assume you have just deployed <https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-initialization> and still have the SSL cert in a environment variable and connection to vault running via `kubectl port-forward`

### Example of the configurations expected by this module

```hcl
vault_configurations = {
  oidc_client_secret = "yolo1234"
  captain_domain     = "nonprod.antoniostacos.onglueops.rocks"
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

### policy\_names

| policy\_name | description                          |
|-------------|--------------------------------------|
| reader      | read all secrets                     |
| editor      | read/write/delete/update all secrets |

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
| [vault_jwt_auth_backend.default](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/jwt_auth_backend) | resource |
| [vault_jwt_auth_backend_role.default](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/jwt_auth_backend_role) | resource |
| [vault_kubernetes_auth_backend_config.config](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/kubernetes_auth_backend_config) | resource |
| [vault_kubernetes_auth_backend_role.env_roles](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_kubernetes_auth_backend_role.vault_backup](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_mount.secrets_kvv2](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/mount) | resource |
| [vault_policy.admin](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/policy) | resource |
| [vault_policy.editor](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/policy) | resource |
| [vault_policy.reader](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/policy) | resource |
| [vault_policy.super_admin](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/policy) | resource |
| [vault_policy.vault_backup](https://registry.terraform.io/providers/hashicorp/vault/3.14.0/docs/resources/policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_captain_domain"></a> [captain\_domain](#input\_captain\_domain) | Captain Domain for the cluster | `string` | n/a | yes |
| <a name="input_oidc_client_secret"></a> [oidc\_client\_secret](#input\_oidc\_client\_secret) | This is the dex client secret for the 'vault' ClientID | `string` | n/a | yes |
| <a name="input_org_team_policy_mappings"></a> [org\_team\_policy\_mappings](#input\_org\_team\_policy\_mappings) | Each OIDC group should be in the format of GITHUB\_ORG\_NAME:GITHUB\_TEAM\_NAME and the policy name should be either 'reader' or 'editor' | <pre>list(object({<br>    policy_name = string<br>    oidc_groups = list(string)<br>  }))</pre> | <pre>[<br>  {<br>    "oidc_groups": [<br>      "example-org:team1",<br>      "example-org:team2"<br>    ],<br>    "policy_name": "reader"<br>  },<br>  {<br>    "oidc_groups": [<br>      "example-org:team1",<br>      "example-org:team3"<br>    ],<br>    "policy_name": "editor"<br>  }<br>]</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
