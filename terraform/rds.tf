resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.db[*].id

  tags = local.tags
}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "db-sg"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
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

resource "aws_db_instance" "rds" {
  allocated_storage    = 10
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  security_group_names = [aws_security_group.db_sg.id]
}