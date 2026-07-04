#!/bin/bash

# Exit immediately if any command fails
set -e

echo "🚀 Starting One-Click Infrastructure Deployment..."

# 1. Build the AWS Infrastructure (No manual prompts)
echo "🧱 Provisioning AWS Resources with Terraform..."
terraform init
terraform apply -auto-approve

# 2. The Dynamic Handoff (Extracting the IP)
echo "🔍 Extracting Bastion Public IP..."
BASTION_IP=$(terraform output -raw bastion_public_ip)
echo "✅ Bastion IP found: $BASTION_IP"

# Wait a few seconds to ensure the EC2 instance SSH service is fully booted
sleep 15

# 3. Run the Software Configuration via the Dynamic Tunnel
echo "⚙️ Configuring SonarQube via Ansible over Bastion Tunnel..."

# We inject the Bastion IP dynamically into Ansible's SSH arguments right in the command line
ansible-playbook -i ansible/aws_ec2.yml ansible/deploy-sonarqube.yml \
  --ssh-common-args="-o ProxyCommand=\"ssh -W %h:%p -q ubuntu@${BASTION_IP} -i sonarkey.pem -o StrictHostKeyChecking=no\""

echo "🎉 One-Click Deployment Complete!"
