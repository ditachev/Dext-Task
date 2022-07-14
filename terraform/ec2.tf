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

data "template_file" "user_data" {
  template = file("./user_data.tpl")
  vars = {
    db_name         = var.db_name
    db_username     = var.db_username
    db_password     = var.db_password
    db_rds_endpoint = aws_db_instance.rds.endpoint
  }
}

resource "aws_instance" "web_server" {
  depends_on = [aws_db_instance.rds]

  count = var.web_server_count

  ami                    = data.aws_ami.linux2_ami.id
  instance_type          = var.web_server_instance_class
  subnet_id              = aws_subnet.private[count.index].id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = data.template_file.user_data.rendered

  root_block_device {
    volume_size = var.web_server_disk_size
  }

  tags = merge(local.tags, { "Name" = "wordpress-server-${count.index}" })
}

resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "lb-sg"

  tags = local.tags
}

resource "aws_security_group_rule" "lb_ingress_rule" {
  security_group_id = aws_security_group.lb_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "lb_egress_rule" {
  security_group_id        = aws_security_group.lb_sg.id
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_sg.id
}

resource "aws_lb" "lb" {
  name            = "wordpress-load-balancer"
  subnets         = aws_subnet.public[*].id
  security_groups = [aws_security_group.lb_sg.id]
  internal        = false

  tags = local.tags
}

resource "aws_lb_target_group" "tg" {
  name     = "wordpress-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  tags = local.tags
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  count = length(aws_instance.web_server)

  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web_server[count.index].id
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  tags = local.tags
}