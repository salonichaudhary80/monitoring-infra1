output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "monitoring_sg_id" {
  value = aws_security_group.monitoring.id
}
