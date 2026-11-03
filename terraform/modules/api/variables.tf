variable "name" { type = string }
variable "aws_region" { type = string }
variable "lambda_invoke_arn" { type = string }
variable "lambda_function_arn" { type = string }
variable "user_pool_id" { type = string }
variable "user_pool_client_id" { type = string }
variable "allowed_origins" { type = list(string) }
