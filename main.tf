### IMPORTING THE KEYPAIR GENERATED OUTSIDE OF TF USING THE SSH-KEYGEN  ###
resource "aws_key_pair" "root_module_kp" {
  key_name   = "root-module-kp"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCh4kZjHIeWZ13Hh4POkdt2tp8IV04A2q4ncayce0BN4wPPkxLNY8PX/ZLQU6ykl4geycahZoK0kFiLKMArEp/DDWdwjsWiz9Gx+h3Pils/3z8T3kOa7IvJPGtRZVAO0Y3u2YKNbxsYCxB5N6Ipvm94j9muNm0wZBY9xsGXszosjUcuKzxcUkgR47SNLHs8+JkjnQqa2u3j4YbbxJLb44tx/Swrqhs2DKAd54zN3nPEaaofxBrG5fzezpkRw7pgnZxaqwhsFgvnQW7rs2FIMRTPbZdddtpQin93txvdMEFkyMimf0wHtCkSFCL6cLa4BUViuGioM0Tu4X2eQrTsTfu4eakPpuekuaU+Dse71VSYIxw9c/KZH2KVyyFstrd0OcIIGc8OJCYTY8igOq4iNmY9zphfmgS2mKCGjJ6hhgVMMdaO8o5MR4RnAW9Z5xEWauipruE1t9TPFPGbdz/y/zWm2wr5mx3RrGQahBveKZlpFqxmWwHuUYaWt6spOf7BEhF6H76/QlZWo/QGpNLAQtIkjqcAoURdinT2M7NsRK3fevbjuhvASbb006DrQ8mQERS6A9wICESq6Cp1H6Ns4pJ4n1+8kKHGPleEyxYtiqJ57W5x6Zz+sHrTWGDR/2zGNqHK/I+8A/KPIIC49tSRW/6c+V0hRq0Aop4Y8x7uPWZSBQ=="
}

###  CREATING VPC, SUBNET, ROUTE TABLE, IGW ###
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name = "public-module-vpc"
  cidr = "10.52.0.0/16"
  azs  = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  vpc_tags = {
    Name = "public-module-vpc"
  }
  enable_dns_hostnames = true
  enable_dns_support   = true

  # PUBLIC SUBNET RELATED VARIABLES
  public_subnets       = ["10.52.1.0/24", "10.52.2.0/24", "10.52.3.0/24"]
  public_subnet_suffix = "public-module-subnet"
  public_subnet_tags = {
    Name = "public-module-subnet"
  }

  #INTERNET GATEWAY RELATED VARIABLES
  igw_tags = {
    Name = "public-module-igw"
  }
}

### SECURITY GROUP CREATION ###
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"

  name        = "public-module-sg"
  description = "Security group created by using the public module"
  vpc_id      = module.vpc.vpc_id
  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH port for management"
      cidr_blocks = "1.2.3.4/32"
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = -1
      to_port     = -1
      protocol    = -1
      description = "Allow all outgoing"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = {
    Name = "public-module-sg"
  }
}



### CREATING THE EC2 INSTANCE ###
data "aws_ami" "root_module_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "ec2_instance" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "5.6.0"
  name                   = "public-module-ec2"
  ami                    = data.aws_ami.root_module_ami.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.security_group.security_group_id]
  key_name               = aws_key_pair.root_module_kp.id
  tags = {
    Name = "public-module-ec2"
  }
}
