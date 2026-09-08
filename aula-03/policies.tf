# ============================================================
# POLICY 1 — S3 READ
# Developers podem apenas consultar dados do S3.
# ============================================================

resource "aws_iam_policy" "s3_read" {
  name        = "${var.ra}-technova-s3-read"
  description = "Permite leitura de objetos dos buckets TechNova"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ListTechnovaBuckets"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = "arn:aws:s3:::technova-*"
      },
      {
        Sid    = "ReadTechnovaObjects"
        Effect = "Allow"

        Action = [
          "s3:GetObject"
        ]

        Resource = "arn:aws:s3:::technova-*/*"
      }
    ]
  })

  tags = local.common_tags
}

# ============================================================
# POLICY 2 — EC2 + S3 FULL
# Platform Engineers podem administrar EC2 e trabalhar
# com dados S3.
#
# Start/Stop da EC2 exige a tag Project=TechNova.
# ============================================================

resource "aws_iam_policy" "ec2_s3_full" {
  name        = "${var.ra}-technova-ec2-s3-full"
  description = "Permissoes de EC2 e leitura/escrita S3 para Platform Engineering"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "DescribeEC2"
        Effect = "Allow"

        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeVolumes",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeTags"
        ]

        Resource = "*"
      },
      {
        Sid    = "StartStopTechNovaInstances"
        Effect = "Allow"

        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ]

        Resource = "arn:aws:ec2:${var.aws_region}:*:instance/*"

        Condition = {
          StringEquals = {
            "ec2:ResourceTag/Project" = var.project_name
          }
        }
      },
      {
        Sid    = "ReadWriteTechnovaS3"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]

        Resource = [
          "arn:aws:s3:::technova-*",
          "arn:aws:s3:::technova-*/*"
        ]
      }
    ]
  })

  tags = local.common_tags
}

# ============================================================
# POLICY 3 — DENY DESTRUTIVO
#
# Impede operações destrutivas mesmo que outra policy
# conceda permissões mais amplas.
# ============================================================

resource "aws_iam_policy" "deny_destructive" {
  name        = "${var.ra}-technova-deny-destructive"
  description = "Bloqueia operacoes destrutivas no ambiente TechNova"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "DenyDestructiveActions"
        Effect = "Deny"

        Action = [
          "s3:Delete*",
          "ec2:Terminate*"
        ]

        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# ============================================================
# POLICY ATTACHMENTS
# ============================================================

resource "aws_iam_group_policy_attachment" "developers_s3_read" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.s3_read.arn
}

resource "aws_iam_group_policy_attachment" "developers_deny_destructive" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.deny_destructive.arn
}

resource "aws_iam_group_policy_attachment" "platform_ec2_s3_full" {
  group      = aws_iam_group.platform_eng.name
  policy_arn = aws_iam_policy.ec2_s3_full.arn
}

resource "aws_iam_group_policy_attachment" "platform_deny_destructive" {
  group      = aws_iam_group.platform_eng.name
  policy_arn = aws_iam_policy.deny_destructive.arn
}