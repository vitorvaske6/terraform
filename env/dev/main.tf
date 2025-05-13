module "aws_dev" {
  source = "../../infra"
  instance = "t2.micro"
  aws_region  = "us-west-2"
  ssh_key = "terraform-instance-ssh"
  enviroment = "DEV"
  min_size = 0
  max_size = 1
}
