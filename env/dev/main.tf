module "aws_dev" {
  source = "../../infra"
  instance = "t2.micro"
  aws_region  = "us-west-2"
  ssh_key = "terraform-instance-ssh"
  enviroment = "DEV"
}

output "ip" {
  value = module.aws_dev.public_ip
}