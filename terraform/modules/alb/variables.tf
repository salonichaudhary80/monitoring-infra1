variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "target_instance_ids" {
  description = "The monitoring servers that run Grafana"
  type        = list(string)
}
