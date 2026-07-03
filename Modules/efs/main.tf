resource "aws_efs_file_system" "main" {
  creation_token  = "${var.project_name}-${var.environment}-efs"
  throughput_mode = var.throughput_mode
}
resource "aws_efs_mount_target" "main" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [var.efs_security_group_id]
}
