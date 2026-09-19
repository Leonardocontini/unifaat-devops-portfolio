resource "aws_db_subnet_group" "main" {
  name = "technova-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_1.id,
    aws_subnet.private_2.id
  ]

  tags = {
    Name    = "${var.project_name}-db-subnet-group"
    Project = var.project_name
    Aula    = "05"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "technova-postgres"

  engine         = "postgres"
  engine_version = "15"

  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.main.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  multi_az            = false
  publicly_accessible = false

  storage_encrypted = true

  skip_final_snapshot = true

  deletion_protection = false

  tags = {
    Name    = "${var.project_name}-postgres"
    Project = var.project_name
    Aula    = "05"
  }
}