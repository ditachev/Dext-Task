terraform {
  backend "s3" {
    bucket = "825144470306-terraform-state"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}
