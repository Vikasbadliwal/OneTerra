# ── 1. Variables to catch data from the root module ───────────
variable "project_name" {}
variable "environment" {}
variable "public_subnet_id" {}
variable "bastion_sg_id" {}
variable "key_name" {}

# ── 2. Find the Ubuntu AMI ────────────────────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ── 3. Build the Bastion Host ─────────────────────────────────
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro" # Keep it small and cheap
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "${var.project_name}-${var.environment}-bastion"
  }
}

# ── 4. Export the Public IP ───────────────────────────────────
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}