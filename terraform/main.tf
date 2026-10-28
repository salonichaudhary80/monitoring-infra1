# ------------------------------------------------------------
# main.tf - joins the 4 modules together (like LEGO blocks)
#
#   vpc  ->  security-groups  ->  ec2  ->  alb
#
# Each module's outputs (IDs) are passed into the next module.
# ------------------------------------------------------------

# 1. Network: VPC, subnets, Internet Gateway, NAT, route tables, NACLs
module "vpc" {
  source = "./modules/vpc"

  project              = var.project
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# 2. Firewalls: alb-sg, bastion-sg, monitoring-sg
module "security_groups" {
  source = "./modules/security-groups"

  project  = var.project
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = var.vpc_cidr
  my_ip    = var.my_ip
}

# 3. Servers: bastion host + monitoring-a + monitoring-b
module "ec2" {
  source = "./modules/ec2"

  project            = var.project
  key_name           = var.key_name
  instance_type      = var.instance_type
  public_subnet_id   = module.vpc.public_subnet_ids[0]
  private_subnet_ids = module.vpc.private_subnet_ids
  bastion_sg_id      = module.security_groups.bastion_sg_id
  monitoring_sg_id   = module.security_groups.monitoring_sg_id

  # Servers download software through the NAT, so build the NAT first
  depends_on = [module.vpc]
}

# 4. Load balancer + target group (Grafana :3000)
module "alb" {
  source = "./modules/alb"

  project             = var.project
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  alb_sg_id           = module.security_groups.alb_sg_id
  target_instance_ids = module.ec2.monitoring_instance_ids
}
