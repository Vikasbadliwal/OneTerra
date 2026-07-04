# SPDX-License-Identifier: MIT-0
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer (bookmark this URL)"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Route 53 alias zone ID for the ALB"
  value       = module.alb.alb_zone_id
}

output "sonarqube_url" {
  description = "SonarQube web URL"
  value       = "http://${module.alb.alb_dns_name}"
}



output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint (used in Ansible extra-vars)"
  value       = module.rds.rds_endpoint
  sensitive   = true
}

output "efs_id" {
  description = "EFS filesystem ID (shared plugin storage)"
  value       = module.efs.efs_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs for SonarQube ASG"
  value       = module.vpc.private_subnet_ids
}

output "bastion_public_ip" {
  value       = module.bastion.bastion_public_ip
  description = "The public IP of the Bastion Host"
}

# output "s3_state_bucket" {
# description = "S3 bucket used for Terraform state"
# value       = module.s3_backend.bucket_name
# }
