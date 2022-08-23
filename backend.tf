terraform {
  backend "s3" {
    encrypt = true
  }
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.0.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = "1.2.7"
}

provider "aws" {
  profile = var.profile
  region  = var.region
}