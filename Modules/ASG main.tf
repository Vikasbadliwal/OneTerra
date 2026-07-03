variable "project_name" {}
variable "private_subnet_ids" {}
variable "sonarqube_sg_id" {}
variable "instance_type" {}
variable "key_name" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "sonarqube" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.sonarqube_sg_id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      # CRITICAL: This exact tag lets Ansible Dynamic Inventory (aws_ec2.yml) find the server automatically
      Name    = "SonarQube-Server" 
      Service = "SonarQube"
    }
  }
}

resource "aws_autoscaling_group" "sonarqube_asg" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  
  # Active-Passive HA Setup for Community Edition
  desired_capacity = 1
  min_size         = 1
  max_size         = 1

  launch_template {
    id      = aws_launch_template.sonarqube.id
    version = "$Latest"
  }
}