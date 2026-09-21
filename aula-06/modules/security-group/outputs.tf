output "sg_id" {
  description = "ID do Security Group"
  value       = aws_security_group.this.id
}