terraform {
  required_version = "1.11.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }

  # REMOTE BACKEND: ensure the S3 bucket and DynamoDB table exist beforehand.
  backend "s3" {
    bucket         = "practical-devops-file-state"
    key            = "3-tier/terraform.tfstate"
    region         = "us-west-2"
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}
