data "aws_caller_identity" "current" {}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}

resource "aws_vpc" "infra_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "infra_vpc"
  }
}

resource "aws_subnet" "infra_subnet_1" {
  vpc_id            = aws_vpc.infra_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "infra_subnet_1"
  }
}

resource "aws_internet_gateway" "infra_igw" {
  vpc_id = aws_vpc.infra_vpc.id

  tags = {
    Name = "infra_igw"
  }
}

resource "aws_route_table" "infra_route_table" {
  vpc_id = aws_vpc.infra_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.infra_igw.id
  }

  tags = {
    Name = "infra_route_table"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.infra_subnet_1.id
  route_table_id = aws_route_table.infra_route_table.id
}
resource "aws_security_group" "infra_sg" {
  name   = "infra_sg"
  vpc_id = aws_vpc.infra_vpc.id

  ingress {
    description = "SSH ingress"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "infra_sg"
  }
}

resource "aws_key_pair" "keypair" {
  key_name   = "keypair"
  public_key = file(var.pub_key)
}

resource "aws_instance" "infra_ins" {
  ami                         = "ami-0522ab6e1ddcc7055"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.keypair.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.infra_subnet_1.id
  security_groups             = [aws_security_group.infra_sg.id]
  tags = {
    Name = "infra_ins"
  }
}
output "public_ip" {
  value = aws_instance.infra_ins.public_ip
}