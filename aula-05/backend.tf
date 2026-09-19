terraform {
  backend "s3" {
    bucket         = "technova-terraform-state-6325054-20260918"
    key            = "aula-05/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "technova-terraform-lock"
  }
}
