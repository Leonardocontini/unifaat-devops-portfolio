variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Nome do ambiente"
  type        = string
}

variable "subnets" {
  description = "Mapa de subnets públicas e privadas"
  type = map(object({
    cidr = string
    az   = string
    type = string
  }))
}