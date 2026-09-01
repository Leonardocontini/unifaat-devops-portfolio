# ============================================================
# EC2 SERVICE ROLE
# Permite que instâncias EC2 assumam esta role.
# ============================================================

resource "aws_iam_role" "ec2_role" {
  name = "${var.ra}-technova-ec2-role"

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

  tags = local.common_tags
}

# ============================================================
# PERMISSION POLICY DA EC2
# Permite leitura e escrita nos dados da aplicação.
# ============================================================

resource "aws_iam_role_policy" "ec2_s3_access" {
  name = "${var.ra}-technova-ec2-s3-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ListApplicationBucket"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = "arn:aws:s3:::technova-app-data-*"
      },
      {
        Sid    = "ReadWriteApplicationData"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = "arn:aws:s3:::technova-app-data-*/*"
      }
    ]
  })
}

# ============================================================
# INSTANCE PROFILE
# Vincula a IAM Role às instâncias EC2.
# ============================================================

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.ra}-technova-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = local.common_tags
}