terraform {
  backend "s3" {
    bucket = "saloni-terraform-state-738922881666"
    key    = "monitoring-infra/terraform.tfstate"
    region = "us-east-1"
  }
}
