# Setting up instances in AWS with Ansible and Terraform

By following Alura course [Infrastructure as Code](https://cursos.alura.com.br/formacao-infraestrutura-codigo) the objective of this project is to setup a Terraform project of IAC.

This is the first course of the formation [Infrastructure as Code: Setting up instances in AWS with Ansible and Terraform](https://cursos.alura.com.br/course/infraestrutura-codigo-maquinas-aws-ansible-terraform)


## Instalation on Windows

Ansible it's not made to run on windows, so we'll need to install windows WSL to proceed. Run the command below to install the default ubuntu version:
```
wsl --install
```

You will be asked to type a username and choose a password. With the linux setted up execute the commands below:

To install python:
```
sudo apt install python3
```

To install terraform:
```
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

To install Ansible:
```
sudo apt update
sudo apt install software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install ansible
```


## AWS

### IAM - User and Access Keys

After creating a root user, the first step is to go to [IAM (Identity and Access Management)](https://console.aws.amazon.com/iam) and create a new user to serve as a CLI user later.

Through the sidebar, access the Users menu and start the process to create a new one.

While creating the user you should figure it out if it needs access to AWS console, for this use case, it doesn't, but we will allow it anyway so we can learn about user and role management.

Set the password our ask them to do that themselves and hit next.

Create a group or set it to an existing one. **In the group, make sure to grant AmazonEC2FullAccess permission policy so we can use it to setup the EC2 Instance later.**

After the user is created, go to its page if you're not already and hit "Create access key", these key will be used to authenticate the AWS Client in windows.

### AWS CLI
Now it's necessary to configure the AWS CLI to use the tokens created earlier. In the terminal run: 
```
aws configure
```
You will need to provide 
- AWS Access Key ID - **REQUIRED**: Access key from the key generated through [IAM](#iam---user-and-access-keys)
- AWS Secret Access Key - **REQUIRED**: Secret key from the key generated through [IAM](#iam---user-and-access-keys)
- Default region name - **NOT REQUIRED**: Not necessary
- Default output format - **NOT REQUIRED**: Not necessary


### EC2 Instance

## Terraform

For the main.tf file it's necessary to access the Terraform [docs](https://developer.hashicorp.com/terraform/tutorials/) and follow the instructions for the best way to set it up properly. Since we are using AWS, the docs we need is [this](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/aws-build).

### Region

For the region you can decide whichever is best for your use case, for this project we will use the cheapest which is U.S. Oregon's (us-west-2).

### EC2 VM/Instance

EC2 is basically a virtual machine or instance on the AWS Cloud. Once you select the image that best fits your needs, you will need its **AMI ID** which can be found like below:

![AMI ID](/images/ami_id.png)(https://us-west-2.console.aws.amazon.com/ec2/home?region=us-west-2#LaunchInstances:)

The machine specs will be defined at the **Instance type** section. Since we are on studying purpose, we will use the default t2.micro:

![Instance type](/images/instance_type.png)(https://us-west-2.console.aws.amazon.com/ec2/home?region=us-west-2#LaunchInstances:)

The main.tf file should be able to create the instance accordingly to the configs you chose, so it's not necessary to create it in the AWS console.

### INIT

With the main.tf file properly configured, run the command below to initialize. This will not create the instance, it will only download the necessary modules to comunicate with AWS:
```
terraform init
```

The command below will show the current planning for this project. You can use it to make sure everything is ok:
```
terraform plan
```

Now to apply the configuration, we can run the command below. Make sure to review the planning if you haven't already and if it's all good, type "yes" to continue:
```
terraform apply
```

### Security Groups

Before connecting to the instance, it's necessary to setup a security group in **EC2** > **Network & Security** > **Security Groups**.

Select the group you want to edit and then click on **Inbound rules** > **Edit inbound rules**.

You will need to add a new rules with the following configurations:

Rule: IPv4 Access
- Type: All trafic;
- Source type: Anywhere-IPv4

Rule: IPv6 Access
- Type: All trafic;
- Source type: Anywhere-IPv6

Now do the same with the outbound rules on **Outbound rules** > **Edit outbound rules**.

Rule: IPv4 Access
- Type: All trafic;
- Source type: Anywhere-IPv4

Rule: IPv6 Access
- Type: All trafic;
- Source type: Anywhere-IPv6


### Connecting to the Instance

To connect to the instance through SSH it's necessary to create a key pair, otherwise you could only be able to connect using a valid username. For this project we will be creating these key pair.

#### Key Pair

To access it, go to **EC2** > **Network & Security** > **Key Pairs**.

Now create a key pair on the RSA type and .pem format.

After the key pair is created, it's necessary to associate it with the instance on the main.tf at the aws_instance resource.

To apply the changes use the [apply command](#init) we've learned earlier.

**NOTE**: The current instance will be ***TERMINATED*** and a new one will be created in it's place.

#### Connecting with SSH

To use our key pair without sudo privileges, we need to copy the file to the WSL ssh folder with the command below:
```
cp ./keys/terraform-instance.pem ~/.ssh/terraform-instance.pem
```

Now we run the command below to make sure the key won't be publicly visible:
```
chmod 400 "~/.ssh/terraform-instance.pem"
```

To connect to the instance run the command below in a bash terminal or use the public DNS provided (ec2-34-208-196-80.us-west-2.compute.amazonaws.com):
```
ssh -i "~/.ssh/terraform-instance.pem" ubuntu@ec2-34-208-196-80.us-west-2.compute.amazonaws.com
```

After the connection is successful you should be able to use the terminal from the instance like this:

![Connected instance](/images/connected_instance.png)

### Creating a web server

Now that you have the access to the instance, you need to put it to use. The example for this project will be a web server that we will create using busybox. To do that, run the command below:
```
nohup busybox httpd -f -p 8080 &
```

What each part does:
- nohup: continues to run the web server even if we disconnect from the instance;
- busybox: it's a software that combines commom linux commands and features.
- httpd: creates the http server:
  - -f: make sure the server will be not daemonized (run in the current terminal showing it's outputs instead of running it on the background);
  - -p: select the port for the web server to run on.

To access the server, you can get the public IPv4 address of the EC2 instance:
![Instance public IPv4](/images/instance_public_ipv4.png)

The final URL should look like this: http://34.208.196.80:8080/. Since we didn't setup any certificates, it's really important to use the link with **http** and not **https**.

#### Automating the creation with Terraform

Using Terraform we can automate the commands we've just executed to run by the user and as soon as the instance is live. To do that we need to add the user_data in the aws_instance resource like this:
```
user_data = "${file("./scripts/user_data.sh")}"
user_data_replace_on_change = true
```

The user_data.sh file content should look like this:
```
#!/bin/bash
cd /home/ubuntu
echo "<h1>Feito com Terraform</h1>" > index.html
nohup busybox httpd -f -p 8080 &
```

Apply the changes and try the URL again.

**NOTE**: The IPv4 address may change, even if the istance is not terminated.

## Ansible

The problem with the automation using terraform is that everytime you change the file a new instance would be created, so to solve this issue enters Ansible.

We start by creating two files: `hosts.yml` and `playbook.yml` and removing `user_data` and `user_data_replace_on_change` from the aws_instance resource.

Now we execute the command below:
```
ansible-playbook playbook.yml -u ubuntu --private-key "~/.ssh/terraform-instance.pem" -i hosts.yml
```
Flags:
- -u: define the username;
- --private-key: the path for the key pair;
- -i: in wich instance it will execute the commands.

### Executing tasks

The same web server we were able to setup with terraform, we can easily do with Ansible as well. In the playbook yml, under tasks we can setup the following commands:
```
- name: Create index.html file
  copy:
    dest: /home/ubuntu/index.html
    content: <h1>Feito com Terraform e Ansible</h1>

- name: Create web server
  shell: "nohup busybox httpd -f -p 8080 &"
```
Commands:
- name: The name of the task with a brief description;
- copy: Creates a file, providing the destination and the content;
- shell: executes a shell command.

### Installing dependencies

As the project gets more and more complex, we will need to install the dependencies to run the project. We can do that using the following task:
```
- name: Install python3 and virtualenv
  apt:
    pkg:
    - python3
    - virtualenv
    update_cache: true
  become: true
```
Commands:
- apt: Install applications like apt-get, providing pkg with the list of packages to install;
  - update_cache: Update apt cache if its older than cache_valid_time
- become: run tasks as admin

#### Installing dependencies using packages installed

As we installed the necessary applications, we need to also install the dependencies for the project to run. In this example we are doing the project in python, so we will be using pip to install the necessary modules:
```
- name: Installing dependencies with pip (Django and Django REST)
  pip:
    virtualenv: /home/ubuntu/terraform-alura/venv
    name: 
      - django
      - djangorestframework
```
Commands:
- pip: Install modules for python applications;
  - virtualenv: Creates a virtual env for given project;
  - name: Provide the name of the modules that should be installed.

To check if the virtualenv worked as intended activate it in the EC2 instance by accessing the folder created with the task and running the command:
```
. venv/bin/activate
```
or
```
source venv/bin/activate
```

### Django Project

Now we are going to setup a REST API with django using the setup we created until now. First we run the command below to create a new project:
```
django-admin startproject setup .
```
**setup** is the folder name and the dot indicates that the project will be created at its root.

Now we can run the django server by passing the localhost and the port we want, like this:
```
python3 manage.py runserver 0.0.0.0:8000
```

#### Django Host Setup

To allow any machine to access the django application we need to change a setting at **~** > **setup** > **settings.py**. In "ALLOWED_HOSTS" we set the value to `['*']`, which indicates that anyone can access the project URL.

#### Automated Ansible Tasks

The final version of the automated project setup would like this:
```
- name: Project Setup - Check if exists
  stat:
    path: '/home/ubuntu/terraform-alura/setup'
  register: project_setup

- name: Project Setup - Create if not exists
  shell: '. /home/ubuntu/terraform-alura/venv/bin/activate; django-admin startproject setup /home/ubuntu/terraform-alura;'
  when: not project_setup.stat.exists

- name: Project Setup - Change settings
  lineinfile:
    path: /home/ubuntu/terraform-alura/setup/settings.py
    regexp: 'ALLOWED_HOSTS'
    line: 'ALLOWED_HOSTS = ["*"]'
    backrefs: yes

- name: Project Start
  shell: '. /home/ubuntu/terraform-alura/venv/bin/activate; nohup python3 /home/ubuntu/terraform-alura/manage.py runserver 0.0.0.0:8000 &'
```
Commands:
- stat: Check the status of given task;
  - path: Check if the file in the path exists;
- register: Save the stat results;
- when: Execute the task only when given statement is true;
- lineinfile: Edit a line in a file given its path and some other arguments;
  - regexp: Uses regex to find the line;
  - line: Changes the content to what its filled here;
  - backrefs: Doesn't change the file if it doesn't find the regex expression.

# Splitting the enviroments in AWS with Ansible and Terraform

By following Alura course [Infrastructure as Code](https://cursos.alura.com.br/formacao-infraestrutura-codigo) the objective of this project is to setup a Terraform project of IAC.

This is the second course of the formation [Infrastructure as Code: Splitting the enviroments in AWS with Ansible and Terraform](https://cursos.alura.com.br/course/infraestrutura-codigo-aws-ansible-terraform)

## Generating the SSH Keys

We already now that we can generate the key pair through AWS console, now we are doing it through linux SSH and sending them to AWS.

Using the WSL, run ssh-keygen, you will be asked for a path for where to create the file and a passphrase if you would like one.

Create two keys, one for development and one for production.

### Applying the Keys into the AWS Instance

Now to apply the new keys we need to add the following resource in our `main.tf` file:
```
resource "aws_key_pair" "ssh_key" {
  key_name   = "dev"
  public_key = file("./dev/keys/terraform-instance-ssh.pub")
}
```

## Using Multiple Enviroments

The codebase is starting to get bigger and tends to increase even more for the time being. To organize better, we are introducing the concept of enviroments. For now we are going to create only 2, development and production. Run the commands below to do that:

```
mkdir infra
mkdir env
mkdir env/dev
mkdir env/dev/keys
mkdir env/prod
mkdir env/prod/keys

mv terraform-instance-ssh ./env/dev/keys
mv terraform-instance-ssh.pub ./env/dev/keys

mv terraform-instance-ssh-prod ./env/prod/keys
mv terraform-instance-ssh-prod.pub ./env/prod/keys

mv playbook.yml ./env/dev/
touch ./env/prod/playbook.yml
mv hosts.yml infra
mv main.tf infra
touch ./infra/variables.tf
```

### Enviroment Variables

Now that we have multiple enviroments, we should use variables to make sure they use the same base but with different values.

Create a file `variables.tf` and declarate them as the example below:
```
variable "aws_region" {
  type = string
}

variable "ssh_key" {
  type = string  
}

variable "instance" {
  type = string  
}

variable "enviroment" {
  type = string  
}
```
For the variables definitions, the type is the only required attribute, but we can add some others like:
- default
- description
- ephemeral
- nullable
- sensitive
- validation 

Example of validation:
```
validation {
  condition = length(var.aws_region) > 0
  error_message = "AWS region must be specified."
}
```

Now create a new `main.tf` for the development and production enviroment:
```
touch ./env/prod/main.tf
touch ./env/dev/main.tf
```

Inside each `main.tf` we define the variables values:
```
module "aws_dev" {
  source = "../../infra"
  instance = "t2.micro"
  aws_region  = "us-west-2"
  ssh_key = "terraform-instance-ssh"
}
```
Do the same for the production one.


Now we apply it to the `main.tf` from the infrastructure folder using the syntax of `var.` and/or `"${var.}"`:
```
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
```

## Security Groups

Security groups are a essential part of the infrastructure and governance and we can also automate and accelerate it's creation through terraform. To do that create the file `./infra/security_groups.tf`. Now fill the file with the setup below:
```
resource "aws_security_group" "default_sg" {
  name        = "Default Security Group - ${var.enviroment}"
  description = "Default security group for Terraform instance"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Default Security Group - ${var.enviroment}"
  }
}
```
Attributes:
- ingress - This is what defines the inbound rules we setted up earlier at the AWS console;
  - from_port - 0 which means any port;
  - to_port - 0 which means any port;
  - protocol - -1 which means all protocols;
  - cidr_blocks - IPv4 IPs granted where 0.0.0 means any IP and /0 means any amount;
  - ipv6_cidr_blocks - IPv6 IPs granted.
- egress - This is what defines the outbound rules we setted up earlier at the AWS console;
- tags - The name that displays at the AWS console.

## Public IP

To avoid the need to fetch the public IP of the instance everytime it changes, now we are going to use terraform to do it for us.

At the `infra/main.tf` file we need to add the code below:
```
output "public_ip" {
  value = aws_instance.app_server.public_ip
}
```

Now we do the same for the dev `env/dev/main.tf` file:
```
output "ip" {
  value = module.aws_dev.public_ip
}
```

And the production `env/prod/main.tf` file:
```
output "ip" {
  value = module.aws_prod.public_ip
}
```

The output name should be different for the infra file, but the same for the enviroments files.

You can also run the command below to fetch the last output again:
```
terraform output
```

**NOTE**: The output only fetches the information, you will need to manually change the files needed.

## Production Setup

Now we are using Ansible to setup the production build, and for that we are going to clone the repository from Github using the production playbook:
```
- name: Clone Repository
  git:
    repo: 'https://github.com/alura-cursos/clientes-leo-api.git'
    dest: /home/ubuntu/terraform-alura
    version: master
```
Commands:
- git - Define the type of task for Github;
  - repo: The link of the repository with .git at the end;
  - dest: The path for where it will be cloned;
  - version: The branch name;

For private repositories it will be needed to create a SSH key at the instance and the following commands should be defined in the ansible playbook:
```
- name: Clone Repository
  git:
    repo: 'https://github.com/alura-cursos/clientes-leo-api.git'
    dest: /home/ubuntu/terraform-alura
    version: master
    accept_hostkey: yes
    key_file: /home/ubuntu/.ssh/vaske-git-ssh 
```

Now that we have a proper repository, we are going to install all the required dependencies using pyhton's requirements.txt file and we are going to do that with Ansible:
```
- name: Installing dependencies with pip (Django and Django REST)
  pip:
    virtualenv: /home/ubuntu/terraform-alura/venv
    requirements: /home/ubuntu/terraform-alura/requirements.txt
```

To finish the setup of the project, we only need to configure the database and to fix a problem with the module dateutils for the python 3.12 and run the project:
```
- name: Installing dependencies with pip (Django and Django REST)
  pip:
    virtualenv: /home/ubuntu/terraform-alura/venv
    requirements: /home/ubuntu/terraform-alura/requirements.txt

- name: Installing dependencies with pip (setuptools since distutils is deprecated on python 3.12)
  pip:
    virtualenv: /home/ubuntu/terraform-alura/venv
    name: 
      - setuptools

- name: Migrate Database
  shell: '. /home/ubuntu/terraform-alura/venv/bin/activate; python /home/ubuntu/terraform-alura/manage.py migrate'

- name: Load Database
  shell: '. /home/ubuntu/terraform-alura/venv/bin/activate; python /home/ubuntu/terraform-alura/manage.py loaddata clientes.json'

- name: Project Setup - Change settings
  lineinfile:
    path: /home/ubuntu/terraform-alura/setup/settings.py
    regexp: 'ALLOWED_HOSTS'
    line: 'ALLOWED_HOSTS = ["*"]'
    backrefs: yes

- name: Project Start
  shell: '. /home/ubuntu/terraform-alura/venv/bin/activate; nohup python /home/ubuntu/terraform-alura/manage.py runserver 0.0.0.0:8000 &'
```