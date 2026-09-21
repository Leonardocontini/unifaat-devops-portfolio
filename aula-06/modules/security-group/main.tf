resource "aws_security_group" "this" {
  name        = var.name
  description = "Security Group ${var.name}"
  vpc_id      = var.vpc_id

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = var.name
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_security_group_rule" "ingress" {
  for_each = {
    for index, rule in var.ingress_rules :
    index => rule
  }

  type                     = "ingress"
  security_group_id        = aws_security_group.this.id
  description              = each.value.description
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  cidr_blocks              = length(each.value.cidr_blocks) > 0 ? each.value.cidr_blocks : null
  source_security_group_id = each.value.source_security_group_id
}