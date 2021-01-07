provider "aws" {
  region  = "us-east-1"
  version = "3.22.0"
}

terraform {
  backend "s3" {
    bucket = "papabear-tfstate"
    key    = "rds/hooky/hooky.tfstate"
    region = "us-east-1"
  }
}