variable "db_name" {
  description = "Nome do banco de dados"
  type        = string
}

variable "db_username" {
  description = "Usuário master do banco"
  type        = string
}

variable "db_password" {
  description = "Senha master do banco"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "IDs das subnets privadas"
  type        = list(string)
}

variable "security_group_ids" {
  description = "IDs dos Security Groups"
  type        = list(string)
}

variable "instance_class" {
  description = "Classe da instância RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "environment" {
  description = "Nome do ambiente"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}