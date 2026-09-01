variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "TechNova"
}

variable "environment" {
  description = "Ambiente do projeto"
  type        = string
  default     = "lab"
}

variable "aluno" {
  description = "Nome completo do aluno"
  type        = string
  default     = "Leonardo Contini"
}

variable "ra" {
  description = "RA do aluno"
  type        = string
  default     = "6325054"
}

variable "aws_region" {
  description = "Região AWS utilizada no laboratório"
  type        = string
  default     = "us-east-1"
}