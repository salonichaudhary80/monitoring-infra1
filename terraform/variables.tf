# ------------------------------------------------------------
# variables.tf - the inputs (values are in terraform.tfvars)
# ------------------------------------------------------------

variable "region" {
  description = "AWS region (Mumbai)"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project name. Used in tags; the Ansible dynamic inventory finds servers by this tag"
  type        = string
  default     = "monitoring-infra"
}

variable "azs" {
  description = "The two Availability Zones (AZ-1 and AZ-2)"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "vpc_cidr" {
  description = "IP range of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnets (AZ-1, AZ-2)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnets (AZ-1, AZ-2)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "my_ip" {
  description = "Your public IP + /32. Only this IP can SSH into the bastion. Find it with: curl ifconfig.me"
  type        = string
}

variable "key_name" {
  description = "Name of an EC2 key pair that already exists in ap-south-1"
  type        = string
}

variable "instance_type" {
  description = "Size of the two monitoring servers"
  type        = string
  default     = "t3.small"
}
