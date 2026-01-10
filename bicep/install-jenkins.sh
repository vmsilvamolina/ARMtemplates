#!/usr/bin/env bash
set -euo pipefail

apt-get update
apt-get install -y openjdk-17-jre-headless gnupg curl

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update
apt-get install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# Jenkins queda en :8080 detrás de la NSG (solo 443 abierto).
# Termina TLS con un reverse proxy (nginx+certbot o App Gateway) — fuera de este script.