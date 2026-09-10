variable "aws_region" {
  description = "Região da AWS"
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "RA do aluno"
  type        = string
}

variable "key_name" {
  description = "Nome da Key Pair"
  type        = string
  default     = "technova-key"
}