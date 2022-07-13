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

  ingress {
    from_port   = 8000
    to_port     = 80
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

  egress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  tags = local.tags
}

resource "aws_elb" "elb" {
  name               = "wordpress-load-balancer"
  availability_zones = aws_subnet.public[*].availability_zone_id
  security_groups    = [aws_security_group.lb_sg.id]
  internal           = false

  access_logs {
    bucket        = "825144470306-terraform-state"
    bucket_prefix = "wordpress/elb"
  }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = aws_instance.web_server[*].id
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = local.tags
}