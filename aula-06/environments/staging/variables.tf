variable "aws_region" {
  description = "Região AWS"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "ami_id" {
  description = "AMI utilizada pela EC2"
  type        = string
}

variable "key_name" {
  description = "Nome do Key Pair"
  type        = string
}

variable "db_username" {
  description = "Usuário do RDS"
  type        = string
}

variable "db_password" {
  description = "Senha do RDS"
  type        = string
  sensitive   = true
}