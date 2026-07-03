# ── UPDATE 1: DECLARE ALL MODULE VARIABLES AT THE TOP ──────────────────
variable "project_name" {}
variable "environment" {}      # <-- Added environment variable
variable "vpc_id" {}
variable "allowed_ssh_cidr" {}

# 1. ALB Security Group (Allows web traffic from the internet)
resource "aws_security_group" "alb" {
  name   = "${var.project_name}-${var.environment}-alb-sg"
  vpc_id = var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ── UPDATE 2: PLACE BASTION SG BEFORE SONARQUBE SG ─────────────────────
# (Terraform needs this declared so the SonarQube group can reference its ID)
resource "aws_security_group" "bastion_sg" {
  name   = "${var.project_name}-${var.environment}-bastion-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr] # Allows SSH only from your trusted IP
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. SonarQube EC2 Security Group
resource "aws_security_group" "sonarqube" {
  name   = "${var.project_name}-${var.environment}-sq-sg"
  vpc_id = var.vpc_id
  
  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  # ── UPDATE 3: ALTER PORT 22 TO ONLY TRUST THE BASTION ───────────────
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # <-- Replaced cidr_blocks
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. RDS Database Security Group (Only allows traffic from SonarQube)
resource "aws_security_group" "rds" {
  name   = "${var.project_name}-${var.environment}-rds-sg"
  vpc_id = var.vpc_id
  
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sonarqube.id]
  }
}

# 5. EFS Security Group (Allows NFS traffic from SonarQube)
resource "aws_security_group" "efs" {
  name   = "${var.project_name}-${var.environment}-efs-sg"
  vpc_id = var.vpc_id
  
  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.sonarqube.id]
  }
}

# ── UPDATE 4: EXPORT ALL SECURITY GROUP IDs AT THE BOTTOM ──────────────
output "alb_sg_id" { 
  value = aws_security_group.alb.id 
}

output "sonarqube_sg_id" { 
  value = aws_security_group.sonarqube.id 
}

output "rds_sg_id" { 
  value = aws_security_group.rds.id 
}

output "efs_sg_id" { 
  value = aws_security_group.efs.id 
}

output "bastion_sg_id" { 
  value = aws_security_group.bastion_sg.id 
}