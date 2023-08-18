<!-- BEGIN_TF_DOCS -->
# terraform-module-kubernetes-hashicorp-vault-configuration

This terraform module is to help you configure a vault cluster for use with OIDC Authentication and KV Secrets Engine Version 2. This module is part of the opionated GlueOps Platform. If you came here directly then you should probably visit https://github.com/glueops/admiral as that is the starting point.

## Prerequisites

- You need an unsealed vault cluster.
- You need an OIDC client secret that matches what you defined in your deployment of the Platform helm chart (`dex.vault.client_secret`)
- You need a connection to the vault cluster using `kubctl` port forwarding.
- You need to ignore self-signed SSL errors
- A json file called `../vault_access.json` needs to exist relative to the usage of this configuration module. If you ran the vault-initialization properly this file will have been created then.

For more details see: https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-configuration/wiki

### Example usage of module

```hcl
module "configure_vault_cluster" {
  source = "git::https://github.com/GlueOps/terraform-module-kubernetes-hashicorp-vault-configuration.git"
  oidc_client_secret       = "yuS5eWskhW1ifc8R1ffgU+RARS3XM4TCKLEVO9rcXAA="
  captain_domain           = "nonprod.antoniostacos.onglueops.rocks"
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

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_vault"></a> [vault](#provider\_vault) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [vault_auth_backend.kubernetes](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/auth_backend) | resource |
| [vault_jwt_auth_backend.default](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend) | resource |
| [vault_jwt_auth_backend_role.default](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend_role) | resource |
| [vault_kubernetes_auth_backend_config.config](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_config) | resource |
| [vault_kubernetes_auth_backend_role.env_roles](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_kubernetes_auth_backend_role.vault_backup](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kubernetes_auth_backend_role) | resource |
| [vault_mount.secrets_kvv2](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount) | resource |
| [vault_policy.admin](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [vault_policy.editor](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [vault_policy.reader](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [vault_policy.super_admin](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [vault_policy.vault_backup](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) | resource |
| [aws_s3_object.vault_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_object) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_access_key"></a> [aws\_access\_key](#input\_aws\_access\_key) | n/a | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | n/a | `string` | n/a | yes |
| <a name="input_aws_s3_bucket_name"></a> [aws\_s3\_bucket\_name](#input\_aws\_s3\_bucket\_name) | The name of the S3 bucket to create for the tenant. | `string` | n/a | yes |
| <a name="input_aws_s3_key_vault_secret_file"></a> [aws\_s3\_key\_vault\_secret\_file](#input\_aws\_s3\_key\_vault\_secret\_file) | The full key path to the s3 bucket file that contains the vault access information. Do not include S3://BUCKET\_NAME/ in the path. | `string` | n/a | yes |
| <a name="input_aws_secret_key"></a> [aws\_secret\_key](#input\_aws\_secret\_key) | n/a | `string` | n/a | yes |
| <a name="input_captain_domain"></a> [captain\_domain](#input\_captain\_domain) | Captain Domain for the cluster | `string` | n/a | yes |
| <a name="input_oidc_client_secret"></a> [oidc\_client\_secret](#input\_oidc\_client\_secret) | This is the dex client secret for the 'vault' ClientID | `string` | n/a | yes |
| <a name="input_org_team_policy_mappings"></a> [org\_team\_policy\_mappings](#input\_org\_team\_policy\_mappings) | Each OIDC group should be in the format of GITHUB\_ORG\_NAME:GITHUB\_TEAM\_NAME and the policy name should be either 'reader' or 'editor' | <pre>list(object({<br>    policy_name = string<br>    oidc_groups = list(string)<br>  }))</pre> | <pre>[<br>  {<br>    "oidc_groups": [<br>      "example-org:team1",<br>      "example-org:team2"<br>    ],<br>    "policy_name": "reader"<br>  },<br>  {<br>    "oidc_groups": [<br>      "example-org:team1",<br>      "example-org:team3"<br>    ],<br>    "policy_name": "editor"<br>  }<br>]</pre> | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
