# ------------------------------------------------------------
# outputs.tf - printed at the end of "terraform apply"
# ------------------------------------------------------------

output "grafana_url" {
  description = "Open this in your browser (user: admin)"
  value       = "http://${module.alb.alb_dns_name}"
}

output "bastion_public_ip" {
  value = module.ec2.bastion_public_ip
}

output "monitoring_private_ips" {
  value = module.ec2.monitoring_private_ips
}
