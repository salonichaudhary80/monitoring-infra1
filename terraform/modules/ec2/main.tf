# ------------------------------------------------------------
# Module: ec2 - bastion host, monitoring-a, monitoring-b
#
# The "Role" tag is important: the Ansible DYNAMIC INVENTORY
# reads it and puts servers into groups:
#   Role = bastion     -> group "bastion"
#   Role = monitoring  -> group "monitoring"  (Ansible installs software here)
# ------------------------------------------------------------

# Latest Ubuntu 24.04 image
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

# Bastion host (public subnet): the jump server
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.bastion_sg_id]
  key_name               = var.key_name

  tags = {
    Name = "bastion-host"
    Role = "bastion"
  }
}

# monitoring-a (AZ-1) and monitoring-b (AZ-2): one in each private subnet
locals {
  monitoring_names = ["monitoring-a", "monitoring-b"]
}

resource "aws_instance" "monitoring" {
  count                  = length(local.monitoring_names)
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index]
  vpc_security_group_ids = [var.monitoring_sg_id]
  key_name               = var.key_name

  tags = {
    Name = local.monitoring_names[count.index]
    Role = "monitoring"
  }
}
