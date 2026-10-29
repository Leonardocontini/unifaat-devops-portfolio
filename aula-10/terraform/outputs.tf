output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.app.public_ip
}

output "ec2_public_dns" {
  description = "DNS público da instância EC2"
  value       = aws_instance.app.public_dns
}

output "ecr_repository_url" {
  description = "URL do repositório ECR"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  description = "Nome do repositório ECR"
  value       = aws_ecr_repository.app.name
}

output "health_check_url" {
  description = "URL do health check da aplicação"
  value       = "http://${aws_instance.app.public_ip}:3000/health"
}

output "app_url" {
  description = "URL da aplicação"
  value       = "http://${aws_instance.app.public_ip}:3000"
}

output "vpc_id" {
  description = "ID da VPC criada"
  value       = aws_vpc.main.id
}
