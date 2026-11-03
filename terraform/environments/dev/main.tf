terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws     = { source = "hashicorp/aws", version = ">= 6.0" }
    archive = { source = "hashicorp/archive", version = ">= 2.4" }
  }
}
provider "aws" { region = var.aws_region }

data "aws_partition" "current" {}

locals {
  embedding_model_arn  = "arn:${data.aws_partition.current.partition}:bedrock:${var.aws_region}::foundation-model/amazon.titan-embed-text-v2:0"
  generation_model_arn = "arn:${data.aws_partition.current.partition}:bedrock:${var.aws_region}::foundation-model/amazon.nova-lite-v1:0"
}

module "storage" {
  source = "../../modules/storage"
  name   = var.project_name
}

module "auth" {
  source = "../../modules/auth"
  name   = var.project_name
}

module "rag" {
  source              = "../../modules/rag"
  name                = var.project_name
  aws_region          = var.aws_region
  document_bucket_arn = module.storage.document_bucket_arn
  embedding_model_arn = local.embedding_model_arn
}

module "api" {
  source              = "../../modules/api"
  name                = var.project_name
  aws_region          = var.aws_region
  lambda_invoke_arn   = module.query_lambda.invoke_arn
  lambda_function_arn = module.query_lambda.function_arn
  user_pool_id        = module.auth.user_pool_id
  user_pool_client_id = module.auth.user_pool_client_id
  allowed_origins     = var.allowed_origins
}

module "query_lambda" {
  source             = "../../modules/query_lambda"
  name               = var.project_name
  source_dir         = "${path.root}/../../../src/query"
  knowledge_base_id  = module.rag.knowledge_base_id
  knowledge_base_arn = module.rag.knowledge_base_arn
  model_arn          = local.generation_model_arn
  guardrail_id       = var.guardrail_id
  guardrail_version  = var.guardrail_version
  audit_table_arn    = module.api.audit_table_arn
  audit_table_name   = module.api.audit_table_name
}

module "observability" {
  source = "../../modules/observability"
  name   = var.project_name
}

output "api_url" { value = module.api.api_url }
output "document_bucket" { value = module.storage.document_bucket }
output "user_pool_id" { value = module.auth.user_pool_id }
output "user_pool_client_id" { value = module.auth.user_pool_client_id }
output "knowledge_base_id" { value = module.rag.knowledge_base_id }
output "knowledge_base_data_source_id" { value = module.rag.data_source_id }
