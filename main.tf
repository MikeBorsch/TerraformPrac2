terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}
provider "aws" { #platform
  region = "us-east-1"
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
         tags = {
            Name = "main-vpc"
    }
}

resource "aws_subnet" "public" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1a"
    tags = {
        Name = "public-subnet"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    }

    resource "aws_route_table" "public_rt" {
        vpc_id = aws_vpc.main.id
        route {
            cidr_block = "0.0.0/0"
            gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "public_access" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "nginx_sg" {
   name = "nginx_sg"
   description = "Allows HTTP and SSH access"
   vpc_id = aws_vpc.main.id
   
   ingress {
    description = "SSH"
    from_port = 22 
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }

   ingress {
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   }

   egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
   }
}
   resource "aws_instance" "nginx" {
    ami = "ami-0C101f26F147Fa7fd"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [aws_security_group.nginx_sg.id]
    associate_public_ip_address = true
    key_name = var.key_name

    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                amazon-linux-extras install nginx1 -y
                systemctl enable nginx
                systemctl start nginx
                echo "<h1>Mike created this Terraform script</h1>" > /usr/share/nginx/html/index.html
                EOF
  
    tags = {
        Name = "nginx-server"
    }
   }