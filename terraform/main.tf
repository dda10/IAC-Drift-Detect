terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region  = "ap-southeast-1"
}

resource "aws_instance" "ec2_instance" {
  ami           = "ami-0435fcf800fb5418d"
  instance_type = "t2.micro"

  tags = {
    owner = "dda"
    environment = "dev"
  }
}