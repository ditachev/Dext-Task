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

  deregistration_delay = 30
  target_type          = "instance"

  health_check {
    enabled             = true
    path                = "/"
    port                = 80
    timeout             = 15
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

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
