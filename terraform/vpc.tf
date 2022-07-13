resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, { "Name" = "wordpress-vpc" })
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_subnet_cidrs[count.index]

  tags = merge(local.tags, { "Name" = "wordpress-private-subnet-${count.index}" })
}

resource "aws_subnet" "public" {
  depends_on = [aws_subnet.private]

  count = length(var.private_subnet_cidrs) # this is to ensure that the number of public subnets matches the number of private subnets

  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone_id = aws_subnet.private[count.index].availability_zone_id # match the AZs of the private subnets to the public subnets
  map_public_ip_on_launch = true # to make this a proper public subnet

  tags = merge(local.tags, { "Name" = "wordpress-public-subnet-${count.index}" })
}

resource "aws_subnet" "db" {
  count      = length(var.db_subnet_cidrs)
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.db_subnet_cidrs[count.index]

  tags = merge(local.tags, { "Name" = "wordpress-db-subnet-${count.index}" })
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
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}
