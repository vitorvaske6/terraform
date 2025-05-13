module "aws_prod" {
  source = "../../infra"
  instance = "t2.micro"
  aws_region  = "us-west-2"
  ssh_key = "terraform-instance-ssh-prod"
  enviroment = "PROD"
  min_size = 1
  max_size = 10
}
