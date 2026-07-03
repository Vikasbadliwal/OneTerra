# ── 1. Variables required by this module ────────────────────────
variable "project_name" {}
variable "private_subnet_ids" {}
variable "sonarqube_sg_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "desired_capacity" {}
variable "min_size" {}
variable "max_size" {}
variable "root_volume_size" {}
variable "target_group_arns" {}

# ── 2. Data source to find the latest Ubuntu 22.04 AMI ──────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ── 3. EC2 Launch Template ──────────────────────────────────────
resource "aws_launch_template" "sonarqube" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  
  # UPDATED FOR BASTION ARCHITECTURE:
  # Keeps the instance private. Traffic will tunnel via the Bastion Host.
  network_interfaces {
    security_groups = [var.sonarqube_sg_id]
  }
  
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.root_volume_size
      volume_type = "gp3"
    }
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "SonarQube-Server"
      Service = "SonarQube"
    }
  }
}

# ── 4. Auto Scaling Group ───────────────────────────────────────
resource "aws_autoscaling_group" "sonarqube" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  target_group_arns   = var.target_group_arns
  
  launch_template {
    id      = aws_launch_template.sonarqube.id
    version = "$Latest"
  }
}