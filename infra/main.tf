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
  region  = var.aws_region
}

resource "aws_instance" "app_server" {
  # AMI ID for Ubuntu Server 24.04 LTS in us-west-2
  ami = "ami-075686beab831bb7f"
  # Instance type - 1 vCPU, 1 GiB RAM
  instance_type = var.instance
  key_name      = var.ssh_key
  # user_data = "${file("./scripts/user_data.sh")}"
  # user_data_replace_on_change = true
  tags = {
    Name = "Terraform-Instance-v1.0"
  }
}

resource "aws_key_pair" "ssh_key" {
  key_name   = var.ssh_key
  public_key = file("./keys/${var.ssh_key}.pub")
}

output "public_ip" {
  value = aws_instance.app_server.public_ip
}