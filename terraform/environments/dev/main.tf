terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 6.0" }
  }
}
provider "aws" { region = var.aws_region }

module "storage" {
  source = "../../modules/storage"
  name   = var.project_name
}

module "auth" {
  source = "../../modules/auth"
  name   = var.project_name
}

module "api" {
  source = "../../modules/api"
  name   = var.project_name
}

module "observability" {
  source = "../../modules/observability"
  name   = var.project_name
}
