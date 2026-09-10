# ============================================
# VPC
# ============================================

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "technova-vpc"
  }
}


# ============================================
# AVAILABILITY ZONES
# ============================================

data "aws_availability_zones" "available" {
  state = "available"
}


# ============================================
# SUBNETS PÚBLICAS
# ============================================

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "technova-public-subnet-1"
  }
}


resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "technova-public-subnet-2"
  }
}


# ============================================
# SUBNETS PRIVADAS
# ============================================

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "technova-private-subnet-1"
  }
}


resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "technova-private-subnet-2"
  }
}


# ============================================
# INTERNET GATEWAY
# ============================================

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "technova-igw"
  }
}


# ============================================
# ROUTE TABLE PÚBLICA
# ============================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "technova-public-route-table"
  }
}


# ============================================
# ASSOCIAÇÃO DAS SUBNETS PÚBLICAS
# ============================================

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}


# ============================================
# SECURITY GROUP - API
# ============================================

resource "aws_security_group" "api" {
  name        = "technova-api-sg"
  description = "Security Group da API"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"

    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }


  ingress {
    description = "API Node.js"

    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }


  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }


  tags = {
    Name = "technova-api-sg"
  }
}


# ============================================
# SECURITY GROUP - BANCO DE DADOS
# ============================================

resource "aws_security_group" "database" {
  name        = "technova-db-sg"
  description = "Security Group do banco de dados"
  vpc_id      = aws_vpc.main.id


  ingress {
    description = "PostgreSQL"

    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/16"
    ]
  }


  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }


  tags = {
    Name = "technova-db-sg"
  }
}


# ============================================
# AMAZON LINUX 2023
# ============================================

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = [
    "amazon"
  ]

  filter {
    name = "name"

    values = [
      "al2023-ami-*-x86_64"
    ]
  }

  filter {
    name = "architecture"

    values = [
      "x86_64"
    ]
  }
}


# ============================================
# IAM ROLE PARA EC2
# ============================================

resource "aws_iam_role" "ec2_role" {
  name = "technova-ec2-role"

  assume_role_policy = jsonencode({

    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "technova-ec2-role"
  }
}


# ============================================
# POLICY S3 READ ONLY
# ============================================

resource "aws_iam_role_policy_attachment" "s3_readonly" {

  role = aws_iam_role.ec2_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}


# ============================================
# INSTANCE PROFILE
# ============================================

resource "aws_iam_instance_profile" "ec2_profile" {

  name = "technova-ec2-profile"

  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "technova-ec2-profile"
  }
}


# ============================================
# KEY PAIR
# ============================================

resource "tls_private_key" "ec2_key" {

  algorithm = "RSA"

  rsa_bits = 4096
}


resource "aws_key_pair" "ec2_key" {

  key_name = var.key_name

  public_key = tls_private_key.ec2_key.public_key_openssh

  tags = {
    Name = "technova-key-pair"
  }
}


# ============================================
# EC2
# ============================================

resource "aws_instance" "api" {

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  subnet_id = aws_subnet.public_1.id

  vpc_security_group_ids = [
    aws_security_group.api.id
  ]

  key_name = aws_key_pair.ec2_key.key_name


  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name


  user_data = file("${path.module}/user_data.sh")


  tags = {
    Name = "technova-api"
  }
}