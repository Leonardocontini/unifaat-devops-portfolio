output "vpc_id" {
  description = "ID da VPC"
  value       = module.vpc.vpc_id
}

output "api_security_group_id" {
  description = "ID do Security Group da API"
  value       = module.api_sg.sg_id
}

output "rds_security_group_id" {
  description = "ID do Security Group do RDS"
  value       = module.rds_sg.sg_id
}

output "ec2_instance_id" {
  description = "ID da EC2"
  value       = module.api_server.instance_id
}

output "ec2_public_ip" {
  description = "IP público da EC2"
  value       = module.api_server.public_ip
}

output "ec2_private_ip" {
  description = "IP privado da EC2"
  value       = module.api_server.private_ip
}

output "rds_endpoint" {
  description = "Endpoint do RDS"
  value       = module.database.db_endpoint
}

output "rds_db_name" {
  description = "Nome do banco RDS"
  value       = module.database.db_name
}

output "rds_port" {
  description = "Porta do RDS"
  value       = module.database.db_port
}