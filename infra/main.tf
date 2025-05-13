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

resource "aws_launch_template" "machine" {
  # AMI ID for Ubuntu Server 24.04 LTS in us-west-2
  image_id = "ami-075686beab831bb7f"
  # Instance type - 1 vCPU, 1 GiB RAM
  instance_type = var.instance
  key_name      = var.ssh_key
  # user_data = "${file("./scripts/user_data.sh")}"
  # user_data_replace_on_change = true
  tags = {
    Name = "Terraform-Instance-v1.0"
  }
  security_group_names = ["Default Security Group - ${var.enviroment}"]
  user_data            = var.enviroment == "PROD" ? ("ansible_setup.sh") : ""
}

resource "aws_key_pair" "ssh_key" {
  key_name   = var.ssh_key
  public_key = file("./keys/${var.ssh_key}.pub")
}

resource "aws_autoscaling_group" "as_group" {
  name               = "AutoScalingGroup-${var.enviroment}"
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  max_size           = var.max_size
  min_size           = var.min_size
  launch_template {
    id      = aws_launch_template.machine.id
    version = "$Latest"
  }
  target_group_arns = var.enviroment == "PROD" ? [aws_lb_target_group.load_balancer_target_group[0].arn] : []
}

resource "aws_default_subnet" "subnet_1" {
  availability_zone = "${var.aws_region}a"
}

resource "aws_default_subnet" "subnet_2" {
  availability_zone = "${var.aws_region}b"
}

resource "aws_default_vpc" "default" {}

resource "aws_lb" "load_balancer" {
  internal = false
  subnets  = [aws_default_subnet.subnet_1.id, aws_default_subnet.subnet_2.id]
  count    = var.enviroment == "PROD" ? 1 : 0
}

resource "aws_lb_target_group" "load_balancer_target_group" {
  name     = "lb-target-group-${var.enviroment}"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id
  count    = var.enviroment == "PROD" ? 1 : 0
}

resource "aws_lb_listener" "load_balancer_listener" {
  load_balancer_arn = aws_lb.load_balancer[0].arn
  port              = 8000
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.load_balancer_target_group[0].arn
  }
  count = var.enviroment == "PROD" ? 1 : 0
}

resource "aws_autoscaling_policy" "autoscaling_policy" {
  name                   = "scale-up-${var.enviroment}"
  autoscaling_group_name = aws_autoscaling_group.as_group.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 90.0
  }
  count = var.enviroment == "PROD" ? 1 : 0
}
