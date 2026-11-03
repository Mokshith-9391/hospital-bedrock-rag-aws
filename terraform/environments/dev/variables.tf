variable "aws_region" { default = "ap-south-1" }
variable "project_name" { default = "hospital-bedrock-rag" }

variable "allowed_origins" {
  type    = list(string)
  default = ["http://localhost:5173"]
}

variable "knowledge_base_id" { type = string }
variable "knowledge_base_arn" { type = string }
variable "model_arn" { type = string }
variable "guardrail_id" {
  type    = string
  default = ""
}

variable "guardrail_version" {
  type    = string
  default = "DRAFT"
}
