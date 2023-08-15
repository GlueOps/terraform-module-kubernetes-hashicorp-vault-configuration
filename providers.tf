terraform {
  required_providers {

    vault = {
      source = "hashicorp/vault"
    }

  }
}

variable "region" {
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

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
