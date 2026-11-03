variable "name" { type = string }
variable "aws_region" { type = string }
variable "document_bucket_arn" { type = string }
variable "document_prefix" {
  type    = string
  default = "documents/"
}
variable "embedding_model_arn" { type = string }
