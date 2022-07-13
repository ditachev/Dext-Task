terraform {
  backend "s3" {
    bucket = "825144470306-terraform-state"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}

locals {
  tags = {
    Owner       = "dimitartachev"
    App         = "wordpress"
    Provisioner = "terraform"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, { "Name" = "wordpress-vpc" })
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_subnet_cidr

  tags = merge(local.tags, { "Name" = "wordpress-private-subnet" })
}

resource "aws_subnet" "db" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.db_subnet_cidr

  tags = merge(local.tags, { "Name" = "wordpress-db-subnet" })
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet_cidr

  tags = merge(local.tags, { "Name" = "wordpress-public-subnet" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.tags, { "Name" = "wordpress-igw" })
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.tags, { "Name" = "wordpress-public-rt" })
}

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}
