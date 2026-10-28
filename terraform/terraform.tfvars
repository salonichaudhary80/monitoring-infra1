# ------------------------------------------------------------
# terraform.tfvars - YOUR values. Change the first 2 lines.
# ------------------------------------------------------------

my_ip    = "106.219.165.107/32"
key_name = "grafana-vm-demo-key" # EC2 key pair name in Mumbai

region               = "ap-south-1"
project              = "monitoring-infra"
azs                  = ["ap-south-1a", "ap-south-1b"]
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
instance_type        = "t3.small"
