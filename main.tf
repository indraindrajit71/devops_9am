#Basic Setup Initially

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

#VPC creation
resource "aws_vpc" "vpc8am" {
  cidr_block       = "10.0.0.0/16"
  #instance_tenancy = "default"

  tags = {
    Name = "VPC8AM"
  }
}

#Subnets Creation
resource "aws_subnet" "subnet8am" {
  vpc_id     = aws_vpc.vpc8am.id 
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "SUBNET8AM"
  }
}

#Internet Gateway Creation
resource "aws_internet_gateway" "igw8am" {
  vpc_id = aws_vpc.vpc8am.id

  tags = {
    Name = "IGW8AM"
  }
}

#Route-Table Creation
resource "aws_route_table" "route8am" {
  vpc_id = aws_vpc.vpc8am.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw8am.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id             = aws_internet_gateway.igw8am.id
    #egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  }

  tags = {
    Name = "ROUTE8AM"
  }
}

#Route-Table-Association-SubnetAssociation
resource "aws_route_table_association" "association8am" {
  subnet_id      = aws_subnet.subnet8am.id 
  route_table_id = aws_route_table.route8am.id 
}

#SecurityGroup-Creation
resource "aws_security_group" "securitygroup8am" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc8am.id 

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

ingress {
    description      = "SSH-Access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP-Traffic"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"   #All the protocols
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "SECURITYGROUP8AM"
  }
}

# Network-Interface
resource "aws_network_interface" "networkinterface8am" {
  subnet_id       = aws_subnet.subnet8am.id 
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.securitygroup8am.id]

  #attachment {
  #  instance     = aws_instance.test.id
  #  device_index = 1
  #}
}

# Create Public/elastic IP
resource "aws_eip" "elastic8am" {
  vpc = true
  #instance                  = aws_instance.foo.id
  network_interface         = aws_network_interface.networkinterface8am.id 
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.igw8am,aws_instance.DevOps]
}

# Instance Creation
resource "aws_instance" "DevOps" {
  ami           = "ami-005de95e8ff495156"
  instance_type = "t2.micro"
  key_name = "jenkins"
  availability_zone = "us-east-1b"
  network_interface {
    network_interface_id = aws_network_interface.networkinterface8am.id
    device_index         = 0
  }
user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install apache2 -y
            sudo systemctl start apache2
            sudo systemctl enable apache2
            sudo bash -c "echo Hey Folks!! Welcome to DevOps World > /var/www/html/index.html"
            EOF
  tags = {
    Name = "DevOpsWorld"
  }
}







