module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr     = var.vpc_cidr
  project_name = var.project_name
  environment  = var.environment

  subnets = {
    public-1 = {
      cidr = "10.0.1.0/24"
      az   = "us-east-1a"
      type = "public"
    }

    public-2 = {
      cidr = "10.0.2.0/24"
      az   = "us-east-1b"
      type = "public"
    }

    private-1 = {
      cidr = "10.0.3.0/24"
      az   = "us-east-1a"
      type = "private"
    }

    private-2 = {
      cidr = "10.0.4.0/24"
      az   = "us-east-1b"
      type = "private"
    }
  }
}

module "api_sg" {
  source = "../../modules/security-group"

  name         = "technova-dev-api-sg"
  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name

  ingress_rules = [
    {
      description              = "SSH"
      from_port                = 22
      to_port                  = 22
      protocol                 = "tcp"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
    },
    {
      description              = "HTTP"
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      cidr_blocks              = ["0.0.0.0/0"]
      source_security_group_id = null
    }
  ]
}

module "rds_sg" {
  source = "../../modules/security-group"

  name         = "technova-dev-rds-sg"
  vpc_id       = module.vpc.vpc_id
  environment  = var.environment
  project_name = var.project_name

  ingress_rules = [
    {
      description              = "PostgreSQL from API"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      cidr_blocks              = []
      source_security_group_id = module.api_sg.sg_id
    }
  ]
}

module "api_server" {
  source = "../../modules/ec2"

  instance_name = "technova-dev-api"
  instance_type = "t2.micro"
  ami_id        = var.ami_id

  subnet_id          = module.vpc.public_subnet_ids[0]
  security_group_ids = [module.api_sg.sg_id]

  key_name = var.key_name

  iam_instance_profile = "LabInstanceProfile"

  environment  = var.environment
  project_name = var.project_name

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
  EOF
}

module "database" {
  source = "../../modules/rds"

  db_name     = "technova_dev"
  db_username = var.db_username
  db_password = var.db_password

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.rds_sg.sg_id]

  instance_class = "db.t3.micro"

  environment  = var.environment
  project_name = var.project_name
}