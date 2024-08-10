provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "zfw-regression-tf-state-data"
    region = "us-east-1"
  }
}