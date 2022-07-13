variable "aws_region" {
  description = "The region to deploy the AWS resources to"
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the main VPC"
  default     = "10.1.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.1.111.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default     = "10.1.1.0/24"
}

variable "db_subnet_cidr" {
  description = "CIDR block for the db subnet"
  default     = "10.1.2.0/24"
}
