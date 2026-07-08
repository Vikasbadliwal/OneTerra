# SPDX-License-Identifier: MIT-0

# ── General Configuration ─────────────────────────────────────────
aws_region   = "ap-south-1"
project_name = "sonarqube"
environment  = "prod"

# ── Networking ────────────────────
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
db_subnet_cidrs      = ["10.0.5.0/24", "10.0.6.0/24"]

# ── EC2 Access ────────────────────────────────────────────────────
key_name         = "sonarkey"
allowed_ssh_cidr = "0.0.0.0/0"

# ── SonarQube Compute ─────────────────────────────────────────────
sonarqube_instance_type    = "c7i-flex.large"
sonarqube_desired_capacity = 1
sonarqube_min_size         = 1
sonarqube_max_size         = 1
sonarqube_root_volume_size = 50

# ── RDS PostgreSQL ────────────────────────────────────────────────
db_username              = "sonar"
db_instance_class        = "db.t3.micro"
db_allocated_storage     = 30
db_max_allocated_storage = 50
# Note: db_password is intentionally omitted for security. 
# It is injected dynamically by the CI/CD pipeline via TF_VAR_db_password.

# ── Application Load Balancer ─────────────────────────────────────
certificate_arn            = ""     # Leave blank for HTTP only
enable_deletion_protection = false
