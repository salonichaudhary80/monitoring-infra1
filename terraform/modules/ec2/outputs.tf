output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "monitoring_instance_ids" {
  value = aws_instance.monitoring[*].id
}

output "monitoring_private_ips" {
  value = zipmap(aws_instance.monitoring[*].tags.Name, aws_instance.monitoring[*].private_ip)
}

