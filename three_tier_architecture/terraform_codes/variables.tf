variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.100.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.100.1.0/24", "10.100.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.100.11.0/24", "10.100.12.0/24"]
}

variable "env" {
  type    = string
  default = "dev"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_desired_capacity" {
  type    = number
  default = 2
}

variable "app_min_size" {
  type    = number
  default = 2
}

variable "app_max_size" {
  type    = number
  default = 4
}

variable "key_pair_name" {
  type    = string
  default = "web-key"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "dbadmin"
}

variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "db_secret_name" {
  description = "Name of the secret in AWS Secrets Manager that stores the DB credentials"
  type        = string
}

variable "bastion_instance_type" {
  type    = string
  default = "t3.nano"
}

# AMI: we will use a data lookup for a public Amazon Linux 2 AMI
