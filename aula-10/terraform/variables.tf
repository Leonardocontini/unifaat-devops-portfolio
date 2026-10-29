variable "aws_region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto — usado como prefixo nos recursos"
  type        = string
  default     = "technova-aula10"
}

variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "O ambiente deve ser 'dev', 'staging' ou 'prod'."
  }
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nome do par de chaves EC2 para acesso SSH"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR liberado para SSH (use o IP do GitHub Actions ou runner)"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrnetmask(var.allowed_ssh_cidr))
    error_message = "O valor deve ser um CIDR IPv4 válido."
  }
}

variable "app_port" {
  description = "Porta em que a aplicação escuta dentro do container"
  type        = number
  default     = 3000
}
