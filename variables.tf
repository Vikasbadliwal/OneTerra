# SPDX-License-Identifier: MIT-0

# ── General ──────────────────────────────────────────────────────
variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Prefix used for resource naming"
  type        = string
  default     = "sonarqube"
}

variable "environment" {
  description = "Deployment environment (dev | staging | prod)"
  type        = string
  default     = "prod"
}

# ── Networking ───────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs to deploy across"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDRs for public subnets (ALB, Bastion, NAT GW)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDRs for private subnets (SonarQube EC2)"
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "CIDRs for DB-only subnets (RDS Multi-AZ)"
  type        = list(string)
}

# ── EC2 / Compute ─────────────────────────────────────────────────
variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed for SSH into Bastion Host"
  type        = string
  # Removed open default to prevent accidental security exposures
}

variable "sonarqube_instance_type" {
  description = "EC2 instance type for SonarQube nodes"
  type        = string
  default     = "c7i-flex.large"
}

variable "sonarqube_desired_capacity" {
  description = "Desired number of SonarQube EC2 instances"
  type        = number
  default     = 1
}

variable "sonarqube_min_size" {
  description = "ASG minimum size"
  type        = number
  default     = 1
}

variable "sonarqube_max_size" {
  description = "ASG maximum size"
  type        = number
  default     = 1
}

variable "sonarqube_root_volume_size" {
  description = "Root EBS volume size (GB) for SonarQube nodes"
  type        = number
  default     = 50
}

# ── RDS ───────────────────────────────────────────────────────────
variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "sonar"
}

variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Initial allocated storage in GB for RDS"
  type        = number
  default     = 30
}

variable "db_max_allocated_storage" {
  description = "Max autoscaling storage in GB for RDS"
  type        = number
  default     = 50
}

# ── EFS ───────────────────────────────────────────────────────────
variable "efs_throughput_mode" {
  description = "EFS throughput mode (bursting | provisioned)"
  type        = string
  default     = "bursting"
}

# ── ALB ───────────────────────────────────────────────────────────
variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = false
}