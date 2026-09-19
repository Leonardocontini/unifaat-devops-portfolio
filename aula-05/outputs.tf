output "vpc_id" {
  description = "ID da VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID da subnet pública"
  value       = aws_subnet.public.id
}

output "private_subnet_1_id" {
  description = "ID da primeira subnet privada"
  value       = aws_subnet.private_1.id
}

output "private_subnet_2_id" {
  description = "ID da segunda subnet privada"
  value       = aws_subnet.private_2.id
}

output "ec2_public_ip" {
  description = "IP público da EC2"
  value       = aws_instance.main.public_ip
}

output "ec2_private_ip" {
  description = "IP privado da EC2"
  value       = aws_instance.main.private_ip
}

output "rds_endpoint" {
  description = "Endpoint do RDS"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Porta do RDS"
  value       = aws_db_instance.postgres.port
}

output "database_name" {
  description = "Nome do banco"
  value       = var.db_name
  sensitive   = true
}

output "connection_string" {
  description = "String de conexão PostgreSQL"
  value       = "postgresql://${var.db_username}:SENHA@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${var.db_name}"
  sensitive   = true
}