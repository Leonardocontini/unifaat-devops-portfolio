#!/bin/bash
set -euo pipefail

# Atualiza pacotes e instala Docker
dnf update -y
dnf install -y docker awscli

# Habilita e inicia o serviço Docker
systemctl enable docker
systemctl start docker

# Adiciona o usuário ec2-user ao grupo docker
usermod -aG docker ec2-user

# Configura a renovação automática do login ECR a cada 6 horas
# (o token ECR expira em 12h; renovamos com margem de segurança)
cat > /etc/cron.d/ecr-login <<'EOF'
0 */6 * * * root aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin $(aws ecr describe-repositories --region ${aws_region} --query 'repositories[0].repositoryUri' --output text | cut -d'/' -f1) 2>/dev/null || true
EOF

echo "EC2 inicializada para o projeto ${project_name}"
