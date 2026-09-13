# ============================================
# AVAILABILITY ZONES
# ============================================

data "aws_availability_zones" "available" {

  state = "available"
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


  filter {

    name = "virtualization-type"

    values = [
      "hvm"
    ]
  }
}


# ============================================
# VPC
# ============================================

resource "aws_vpc" "main" {

  cidr_block = "10.0.0.0/16"

  enable_dns_support = true

  enable_dns_hostnames = true


  tags = {

    Name = "technova-vpc"
  }
}


# ============================================
# SUBNET PÚBLICA 1
# ============================================

resource "aws_subnet" "public_1" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.1.0/24"

  availability_zone = data.aws_availability_zones.available.names[0]

  map_public_ip_on_launch = true


  tags = {

    Name = "technova-public-subnet-1"
  }
}


# ============================================
# SUBNET PRIVADA 1
# ============================================

resource "aws_subnet" "private_1" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.2.0/24"

  availability_zone = data.aws_availability_zones.available.names[0]

  map_public_ip_on_launch = false


  tags = {

    Name = "technova-private-subnet-1"
  }
}


# ============================================
# SUBNET PÚBLICA 2
# ============================================

resource "aws_subnet" "public_2" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.3.0/24"

  availability_zone = data.aws_availability_zones.available.names[1]

  map_public_ip_on_launch = true


  tags = {

    Name = "technova-public-subnet-2"
  }
}


# ============================================
# SUBNET PRIVADA 2
# ============================================

resource "aws_subnet" "private_2" {

  vpc_id = aws_vpc.main.id

  cidr_block = "10.0.4.0/24"

  availability_zone = data.aws_availability_zones.available.names[1]

  map_public_ip_on_launch = false


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

    Name = "technova-internet-gateway"
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
# ASSOCIAÇÃO SUBNET PÚBLICA 1
# ============================================

resource "aws_route_table_association" "public_1" {

  subnet_id = aws_subnet.public_1.id

  route_table_id = aws_route_table.public.id
}


# ============================================
# ASSOCIAÇÃO SUBNET PÚBLICA 2
# ============================================

resource "aws_route_table_association" "public_2" {

  subnet_id = aws_subnet.public_2.id

  route_table_id = aws_route_table.public.id
}


# ============================================
# SECURITY GROUP DA API
# ============================================

resource "aws_security_group" "api" {

  name = "technova-api-sg"

  description = "Security Group da API TechNova"

  vpc_id = aws_vpc.main.id


  # SSH

  ingress {

    description = "SSH"

    from_port = 22

    to_port = 22

    protocol = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }


  # API NODE.JS

  ingress {

    description = "API Node.js"

    from_port = 3000

    to_port = 3000

    protocol = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }


  # EGRESS

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }


  tags = {

    Name = "technova-api-sg"
  }
}


# ============================================
# SECURITY GROUP DO BANCO
# ============================================

resource "aws_security_group" "database" {

  name = "technova-db-sg"

  description = "Security Group do banco de dados"

  vpc_id = aws_vpc.main.id


  # POSTGRESQL

  ingress {

    description = "PostgreSQL interno"

    from_port = 5432

    to_port = 5432

    protocol = "tcp"

    cidr_blocks = [
      "10.0.0.0/16"
    ]
  }


  # EGRESS

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }


  tags = {

    Name = "technova-db-sg"
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
# ARQUIVO DA CHAVE PRIVADA
# ============================================

resource "local_file" "private_key" {

  content = tls_private_key.ec2_key.private_key_pem

  filename = "${path.module}/technova-key.pem"

  file_permission = "0400"
}


# ============================================
# EC2 INSTANCE
# ============================================

resource "aws_instance" "api" {

  ami = data.aws_ami.amazon_linux.id

  instance_type = "t2.micro"


  # SUBNET PÚBLICA

  subnet_id = aws_subnet.public_1.id


  # SECURITY GROUP DA API

  vpc_security_group_ids = [

    aws_security_group.api.id
  ]


  # KEY PAIR

  key_name = aws_key_pair.ec2_key.key_name


  # INSTANCE PROFILE DO AWS LEARNER LAB

  iam_instance_profile = "LabInstanceProfile"


  # USER DATA

  user_data = file("${path.module}/user_data.sh")


  tags = {

    Name = "technova-api"
  }
}