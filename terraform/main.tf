terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    okta = {
      source  = "okta/okta"
      version = "~> 4.10.0"
    }
  }
  #backend configuration variables are supplied directly into the Terraform CLI using the backend-*.conf files
  backend "s3" {
  }
}

provider "aws" {
  region = var.region
}

provider "okta" {
  org_name     = var.okta_org_name
  base_url     = var.okta_base_url
  scopes       = var.okta_scopes
  client_id    = var.okta_client_id
  private_key_id = var.okta_private_key_id
  private_key  = data.aws_secretsmanager_secret_version.okta_private_key.secret_string
}

data "aws_secretsmanager_secret_version" "okta_private_key" {
  secret_id = var.okta_secret_id
}

module "directory" {
  source = "./modules/directory"
  okta_group_name = var.okta_group_name
  auth_server_name = var.auth_server_name
  user_first_name = var.user_first_name
  user_last_name = var.user_last_name
  user_login_email = var.user_login_email
}
