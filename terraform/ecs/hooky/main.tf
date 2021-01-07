provider "aws" {
  region  = "us-east-1"
  version = "3.22.0"
}

terraform {
  backend "s3" {
    bucket = "papabear-tfstate"
    key    = "ecs/services/hooky.tfstate"
    region = "us-east-1"
  }
}