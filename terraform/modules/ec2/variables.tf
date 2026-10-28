variable "project" {
  type = string
}

variable "key_name" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "public_subnet_id" {
  description = "Subnet for the bastion host"
  type        = string
}

variable "private_subnet_ids" {
  description = "Subnets for monitoring-a and monitoring-b"
  type        = list(string)
}

variable "bastion_sg_id" {
  type = string
}

variable "monitoring_sg_id" {
  type = string
}
