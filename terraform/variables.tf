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

variable "db_subnet_cidrs" {
  description = "CIDR blocks for the db subnets"
  default     = ["10.1.2.0/24", "10.1.3.0/24"]
}

variable "db_name" {
  description = "Name of the MySQL RDS instance"
  default     = "wp_db"
}

variable "db_username" {
  description = "Name of the MySQL RDS instance user"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password of the MySQL RDS instance user"
  type        = string
  sensitive   = true
}

variable "db_engine" {
  description = "Engine of the RDS instance"
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Version of the RDS instance engine"
  default     = "5.7"
}

variable "db_instance_class" {
  description = "Instance class of the RDS instance"
  default     = "db.t2.micro"
}