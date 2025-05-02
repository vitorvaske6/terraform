terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_instance" "app_server" {
  # AMI ID for Ubuntu Server 24.04 LTS in us-west-2
  ami           = "ami-075686beab831bb7f"
  # Instance type - 1 vCPU, 1 GiB RAM
  instance_type = "t2.micro"
  key_name = "terraform-instance"
  # user_data = "${file("./scripts/user_data.sh")}"
  # user_data_replace_on_change = true
  tags = {
    Name = "Terraform-Instance-v0.1"
  }
}
