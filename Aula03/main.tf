locals {
  common_tags = {
    Project    = var.project_name
    ManagedBy  = "Terraform"
    Aluno      = var.aluno
    RA         = var.ra
    Disciplina = "DevOps - UniFAAT 2026-2"
    Aula       = "03"
  }

  developers_group = "${var.ra}-technova-developers"
  platform_group   = "${var.ra}-technova-platform-eng"

  juliana_user = "${var.ra}-juliana-dev"
  rafael_user  = "${var.ra}-rafael-platform"
  lucas_user   = "${var.ra}-lucas-intern"
}

# ============================================================
# IAM GROUPS
# ============================================================

resource "aws_iam_group" "developers" {
  name = local.developers_group
}

resource "aws_iam_group" "platform_eng" {
  name = local.platform_group
}

# ============================================================
# IAM USERS
# ============================================================

resource "aws_iam_user" "juliana" {
  name = local.juliana_user

  tags = local.common_tags
}

resource "aws_iam_user" "rafael" {
  name = local.rafael_user

  tags = local.common_tags
}

resource "aws_iam_user" "lucas" {
  name = local.lucas_user

  tags = local.common_tags
}

# ============================================================
# GROUP MEMBERSHIPS
# ============================================================

resource "aws_iam_group_membership" "developers" {
  name = "${var.ra}-technova-developers-membership"

  users = [
    aws_iam_user.juliana.name,
    aws_iam_user.rafael.name,
    aws_iam_user.lucas.name
  ]

  group = aws_iam_group.developers.name
}

resource "aws_iam_group_membership" "platform_eng" {
  name = "${var.ra}-technova-platform-membership"

  users = [
    aws_iam_user.rafael.name
  ]

  group = aws_iam_group.platform_eng.name
}