variable "name" {
  description = "Nome do Security Group"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "environment" {
  description = "Nome do ambiente"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "ingress_rules" {
  description = "Lista de regras de entrada"
  type = list(object({
    description              = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = list(string)
    source_security_group_id = optional(string)
  }))
  default = []
}