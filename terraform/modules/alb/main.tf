# ------------------------------------------------------------
# Module: alb - "ALB" + "Target group Grafana :3000" in the diagram
# ------------------------------------------------------------

resource "aws_lb" "this" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
}

# Target group: the servers the ALB may send users to
resource "aws_lb_target_group" "grafana" {
  name     = "grafana-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # The ALB checks Grafana's health; unhealthy servers get no users
  health_check {
    path    = "/api/health"
    matcher = "200"
  }

  # Keep a user on the same Grafana so they stay logged in
  stickiness {
    type    = "lb_cookie"
    enabled = true
  }
}

# Add both monitoring servers to the target group
resource "aws_lb_target_group_attachment" "grafana" {
  count            = length(var.target_instance_ids)
  target_group_arn = aws_lb_target_group.grafana.arn
  target_id        = var.target_instance_ids[count.index]
  port             = 3000
}

# Listener: port 80 on the ALB -> target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}
