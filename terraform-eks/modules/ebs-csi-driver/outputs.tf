output "ebs_csi_controller_role_arn" {
  description = "ARN da role IAM do EBS CSI Controller"
  value       = aws_iam_role.ebs_csi_controller.arn
} 