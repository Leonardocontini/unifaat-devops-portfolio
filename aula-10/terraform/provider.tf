terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend S3 para estado remoto — substitua bucket e região conforme seu Lab
  # Para usar: terraform init -backend-config="bucket=<SEU-BUCKET>" -backend-config="key=aula-10/terraform.tfstate"
  backend "s3" {
    bucket = "unifaat-devops-tfstate"
    key    = "aula-10/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  # Nota de autenticação:
  # No Learner Lab as credenciais temporárias de sessão são injetadas via
  # variáveis de ambiente (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,
  # AWS_SESSION_TOKEN) pelo workflow do GitHub Actions.
  #
  # Em produção fora do Lab, o padrão ideal é OIDC + IAM Role:
  #   assume_role { role_arn = "arn:aws:iam::<ACCOUNT>:role/github-actions-role" }
  # Dessa forma nenhuma chave de longa duração precisa ser armazenada.
  # O Lab não permite criar OIDC provider nem roles IAM, por isso usamos secrets.
}
