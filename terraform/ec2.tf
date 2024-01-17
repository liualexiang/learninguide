provider "aws" {
  profile = "default"
  region = "cn-north-1"
}

resource "aws_vpc" "terraform_vpc" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "terraform_vpc"
  }
}

resource "aws_subnet" "public_subnet_01" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"
  availability_zone = "cn-north-1a"
  cidr_block = "${cidrsubnet(aws_vpc.terraform_vpc.cidr_block, 4, 1)}"
}

resource "aws_internet_gateway" "igw" {
  vpc_id="${aws_vpc.terraform_vpc.id}"
  
  tags = {
    Name = "terraform_igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags = {
    Name = "terraform_public"
  }
}

resource "aws_route_table_association" "pub" {
  subnet_id = "${aws_subnet.public_subnet_01.id}"
  route_table_id = "${aws_route_table.public.id}"
}

data "aws_ami" "amzn2" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["amzn2-ami-hvm-2.0.20200304.0-x86_64-gp2"]
  }
}

resource "aws_instance" "terraform_test" {
  ami = "${data.aws_ami.amzn2.id}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.public_subnet_01.id}"
  ebs_block_device {
    volume_type="gp2"
    volume_size = "500"
    device_name = "/dev/xvdf"
  }
  key_name = "BJSAWS"
  user_data = "touch /home/ec2-user/testfile_by_terraform"
  
  disable_api_termination = false

  tags = {
    Name = "terraform_instance"
  }
}


