terraform {
  required_version = "~> 1.10.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.82.2"
    }

    vault = {
      source = "hashicorp/vault"
      version = "4.5.0"
    }
  }
}

provider "vault" {
  address = var.vault_address
  token = var.vault_token
}

data "vault_kv_secret_v2" "aws_terraform_creds" {
  mount = "kvv2"
  name = "aws/terraform"
}

provider "aws" {
  region     = "us-east-2"
  access_key = data.vault_kv_secret_v2.aws_terraform_creds.data.access_key_id
  secret_key = data.vault_kv_secret_v2.aws_terraform_creds.data.access_key_value
}