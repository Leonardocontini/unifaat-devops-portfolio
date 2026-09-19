variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Nome globalmente único do bucket S3"
  type        = string
}

variable "lock_table_name" {
  description = "Nome da tabela DynamoDB para locking"
  type        = string
  default     = "technova-terraform-lock"
}