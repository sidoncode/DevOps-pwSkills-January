terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "my-tf-state-sid-bucket"
    key          = "ec2/terraform.tfstate"   # path of the state file inside the bucket
    region       = "us-east-1"
    encrypt      = true
    dynamodb_table = "terraform-locks"
  }
}

provider "aws" {
  region = "us-east-1"
}