variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "TechNova"
}

variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR da subnet pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR da primeira subnet privada"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR da segunda subnet privada"
  type        = string
  default     = "10.0.3.0/24"
}

variable "availability_zone_1" {
  description = "Primeira Availability Zone"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "Segunda Availability Zone"
  type        = string
  default     = "us-east-1b"
}

variable "db_name" {
  description = "Nome do banco PostgreSQL"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "Usuário do PostgreSQL"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Senha do PostgreSQL"
  type        = string
  sensitive   = true
}

variable "key_name" {
  description = "Nome do Key Pair existente na AWS"
  type        = string
}