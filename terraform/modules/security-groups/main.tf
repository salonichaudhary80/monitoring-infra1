# ------------------------------------------------------------
# Module: security-groups - the 3 red dashed boxes in the diagram
# ------------------------------------------------------------

# alb-sg: anyone can open the website (HTTP 80)
resource "aws_security_group" "alb" {
  name   = "alb-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "alb-sg" }
}

# bastion-sg: SSH only from your IP
resource "aws_security_group" "bastion" {
  name   = "bastion-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bastion-sg" }
}

# monitoring-sg: the two monitoring servers
resource "aws_security_group" "monitoring" {
  name   = "monitoring-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Grafana, only from the load balancer"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "node_exporter, so each vmagent can scrape both servers"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description     = "SSH, only from the bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # No rule for VictoriaMetrics 8428: only Grafana on the same server uses it.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "monitoring-sg" }
}
