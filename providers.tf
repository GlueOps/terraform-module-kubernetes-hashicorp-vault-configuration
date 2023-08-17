terraform {
  required_providers {

    vault = {
      source = "hashicorp/vault"
    }

  }
}

variable "aws_region" {
  type = string
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type = string
}

variable "aws_s3_bucket_name" {
  description = "The name of the S3 bucket to create for the tenant."
  type        = string
  nullable    = false
}

variable "aws_s3_key_vault_secret_file" {
  description = "The full key path to the s3 bucket file that contains the vault access information. Do not include S3://BUCKET_NAME/ in the path."
  type        = string
  nullable    = false
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
