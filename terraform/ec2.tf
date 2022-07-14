resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "web-sg"

  tags = local.tags
}

resource "aws_security_group_rule" "web_ingress_rule" {
  security_group_id        = aws_security_group.web_sg.id
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb_sg.id
}

resource "aws_security_group_rule" "web_egress_rule" {
  security_group_id = aws_security_group.web_sg.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
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
  depends_on = [aws_db_instance.rds, aws_lb.lb]

  count = var.web_server_count

  ami                    = data.aws_ami.linux2_ami.id
  instance_type          = var.web_server_instance_class
  subnet_id              = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = templatefile("./user_data.tpl",
    {
      db_name         = var.db_name,
      db_username     = nonsensitive(var.db_username),
      db_password     = nonsensitive(var.db_password),
      db_rds_endpoint = aws_db_instance.rds.endpoint,
      site_url        = aws_lb.lb.dns_name
    }
  )

  root_block_device {
    volume_size = var.web_server_disk_size
  }

  tags = merge(local.tags, { "Name" = "wordpress-server-${count.index}" })
}
