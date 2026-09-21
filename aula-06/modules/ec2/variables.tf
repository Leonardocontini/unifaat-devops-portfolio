variable "instance_name" {
  description = "Nome da instância EC2"
  type        = string
}

variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "ID da AMI"
  type        = string
}

variable "subnet_id" {
  description = "ID da subnet"
  type        = string
}

variable "security_group_ids" {
  description = "Lista de Security Group IDs"
  type        = list(string)
}

variable "key_name" {
  description = "Nome do Key Pair"
  type        = string
}

variable "user_data" {
  description = "Script opcional de inicialização"
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "Nome do Instance Profile do Lab Role"
  type        = string
  default     = "LabInstanceProfile"
}

variable "environment" {
  description = "Nome do ambiente"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}