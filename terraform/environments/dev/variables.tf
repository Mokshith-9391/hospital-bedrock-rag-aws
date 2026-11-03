variable "aws_region" { default = "ap-south-1" }
variable "project_name" { default = "hospital-bedrock-rag" }

variable "allowed_origins" {
  type    = list(string)
  default = ["http://localhost:5173"]
}

variable "guardrail_id" {
  type    = string
  default = ""
}

variable "guardrail_version" {
  type    = string
  default = "DRAFT"
}
