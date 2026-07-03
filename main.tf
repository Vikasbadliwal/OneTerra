# ── 1. State-backend bootstrap ───────
# module "s3_backend" {
#  source       = "./Modules/s3_backend"
# project_name = var.project_name
# environment  = var.environment
# aws_region   = var.aws_region
# }

# ── 2. VPC & Networking ───────────────────────────────────────────
module "vpc" {
  source               = "./Modules/vpc"
  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  db_subnet_cidrs      = var.db_subnet_cidrs
}

# ── 3. Security Groups ────────────────────────────────────────────
module "security_groups" {
  source           = "./Modules/security_groups"
  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}

# ── 4. RDS PostgreSQL Multi-AZ ────────────────────────────────────
module "rds" {
  source                   = "./Modules/rds"
  project_name             = var.project_name
  environment              = var.environment
  db_subnet_ids            = module.vpc.db_subnet_ids
  db_security_group_id     = module.security_groups.rds_sg_id
  db_username              = var.db_username
  db_password              = var.db_password
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_max_allocated_storage = var.db_max_allocated_storage
}

# ── 5. EFS (shared storage for SonarQube plugins/data) ────────────
module "efs" {
  source               = "./Modules/efs"
  project_name         = var.project_name
  environment          = var.environment
  private_subnet_ids   = module.vpc.private_subnet_ids
  efs_security_group_id = module.security_groups.efs_sg_id
  throughput_mode      = var.efs_throughput_mode
}

# ── 6. Application Load Balancer ──────────────────────────────────
module "alb" {
  source                     = "./Modules/alb"
  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  public_subnet_ids          = module.vpc.public_subnet_ids
  alb_security_group_id      = module.security_groups.alb_sg_id
  certificate_arn            = var.certificate_arn
  enable_deletion_protection = var.enable_deletion_protection
}

# ── 7. SonarQube Auto Scaling Group ──────────────────────────────
module "sonarqube" {
  source             = "./Modules/sonarqube"
  project_name       = var.project_name
  private_subnet_ids = module.vpc.private_subnet_ids
  sonarqube_sg_id    = module.security_groups.sonarqube_sg_id
  key_name           = var.key_name
  instance_type      = var.sonarqube_instance_type
  desired_capacity   = var.sonarqube_desired_capacity
  min_size           = var.sonarqube_min_size
  max_size           = var.sonarqube_max_size
  root_volume_size   = var.sonarqube_root_volume_size
  target_group_arns  = [module.alb.target_group_arn]

  depends_on = [module.rds, module.efs]
}

module "bastion" {
  source           = "./Modules/bastion"
  project_name     = var.project_name
  environment      = var.environment
  public_subnet_id = module.vpc.public_subnet_ids[0]
  bastion_sg_id    = module.security_groups.bastion_sg_id
  key_name         = var.key_name
}