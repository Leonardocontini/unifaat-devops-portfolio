#!/bin/bash

set -e

sudo dnf update -y

sudo dnf install -y postgresql15

echo "PostgreSQL client instalado com sucesso." | sudo tee /var/log/technova-user-data.log

psql --version | sudo tee -a /var/log/technova-user-data.log