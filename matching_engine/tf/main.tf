terraform {
  #   backend "s3" {
  #     bucket = "matching-engine-tfstate-bucket"
  #     key    = "infra/terraform.tfstate"
  #     region = "us-east-1"
  #   }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.48"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}