/*

Networking configuration

*/

# Create a VPC
resource "aws_vpc" "app_vpc" {
  cidr_block = "10.2.0.0/16"

  tags = {
    Name = "web-app-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id

  tags = {
    Name = "vpc_igw"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.2.0.0/16"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-2a"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_rt_asso" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "sg" {
  name        = "allow_ssh_http"
  description = "Allow ssh http inbound traffic"
  vpc_id      = aws_vpc.app_vpc.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}

/*

web app

*/

resource "aws_instance" "web" {
  ami             = "ami-02e8cbf7681c3ae51"
  instance_type   = "t2.micro"
  key_name        = "k3s_key"
  subnet_id       = aws_subnet.public_subnet.id
  security_groups = [aws_security_group.sg.id]

  user_data = <<-EOF
  #!/bin/bash
  sudo apt update -y
  sudo apt install apache2 -y
  EOF

  tags = {
    Name = "apache_web_server"
  }

  volume_tags = {
    Name = "apache_web_server"
  }
}

output "web_instance_ip" {
  value = aws_instance.web.public_ip
}
