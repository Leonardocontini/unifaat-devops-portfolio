output "db_endpoint" {
  description = "Endpoint do banco RDS"
  value       = aws_db_instance.this.address
}

output "db_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.this.db_name
}

output "db_port" {
  description = "Porta do banco de dados"
  value       = aws_db_instance.this.port
}