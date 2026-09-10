# ============================================
# VPC
# ============================================

output "vpc_id" {
  description = "ID da VPC"

  value = aws_vpc.main.id
}


# ============================================
# SUBNETS PÚBLICAS
# ============================================

output "public_subnet_ids" {
  description = "Lista com IDs das subnets públicas"

  value = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]
}


# ============================================
# SUBNETS PRIVADAS
# ============================================

output "private_subnet_ids" {
  description = "Lista com IDs das subnets privadas"

  value = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]
}


# ============================================
# SECURITY GROUP API
# ============================================

output "api_security_group_id" {
  description = "ID do Security Group da API"

  value = aws_security_group.api.id
}


# ============================================
# SECURITY GROUP DATABASE
# ============================================

output "db_security_group_id" {
  description = "ID do Security Group do banco"

  value = aws_security_group.database.id
}


# ============================================
# IP PÚBLICO
# ============================================

output "ec2_public_ip" {
  description = "IP público da instância EC2"

  value = aws_instance.api.public_ip
}


# ============================================
# URL DA API
# ============================================

output "api_url" {
  description = "URL completa da API"

  value = "http://${aws_instance.api.public_ip}:3000"
}


# ============================================
# COMANDO SSH
# ============================================

output "ssh_command" {
  description = "Comando SSH para conectar na EC2"

  value = "ssh -i technova-key.pem ec2-user@${aws_instance.api.public_ip}"
}