provider "aws" {
  profile = "default"
  region = "cn-north-1"
}

data "template_file" "ec2_userdata" {
  template = file("${path.module}/ec2_userdata.tpl")
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

resource "aws_security_group" "web_sg" {
  name = "web_sg"
  description = "open port 80 and 6666"
  vpc_id = aws_vpc.terraform_vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
  from_port = 0
  to_port = 0
  protocol ="-1"
  cidr_blocks = ["0.0.0.0/0"]
}

tags = {
  Name = "Terrafrom Web SG"
}
}



resource "aws_instance" "terraform_test" {
  count = 1
  ami = "${data.aws_ami.amzn2.id}"
  instance_type = "t2.2xlarge"
  subnet_id = "${aws_subnet.public_subnet_01.id}"
  ebs_block_device {
    volume_type="gp2"
    volume_size = "500"
    device_name = "/dev/xvdf"
  }
  key_name = "BJSAWS"
#  user_data = data.template_file.ec2_userdata.rendered
#  user_data_base64 = base64encode(data.template_file.ec2_userdata.rendered)
  user_data = base64encode(data.template_file.ec2_userdata.rendered)
  disable_api_termination = false

  security_groups = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "terraform_instance"
  }
}

output "superset_login_address" {
  value = format("SuperSet login address is: http://%s", aws_instance.terraform_test[0].public_ip)
}