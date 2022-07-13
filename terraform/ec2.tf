resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "web-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.tags
}

data "aws_ami" "linux2_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }


  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web_server" {
  depends_on = [aws_db_instance.rds]

  count = var.web_server_count

  ami                    = data.aws_ami.linux2_ami.id
  instance_type          = var.web_server_instance_class
  subnet_id              = aws_subnet.private[count.index].id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  root_block_device {
    volume_size = var.web_server_disk_size
  }

  tags = merge(local.tags, { "Name" = "wordpress-server-${count.index}" })
}

resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "lb-sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  tags = local.tags
}

data "aws_availability_zones" "subnet_az" {
  filter {
    name   = "zone-id"
    values = aws_subnet.public[*].availability_zone_id
  }
}

resource "aws_lb" "lb" {
  name            = "wordpress-load-balancer"
  subnets         = aws_subnet.public[*].id
  security_groups = [aws_security_group.lb_sg.id]
  internal        = false

  tags = local.tags
}

