variable "azs" {
  type        = list(string)
  description = "AZs used for subnets"
}

variable "public_subnets" {
  type        = list(string)
  description = "public subnet ranges"
}

variable "private_subnets" {
  type        = list(string)
  description = "private subnet ranges"
}

variable "vpc_cidr" {
  type        = string
  description = "vpc IP range"
}

variable "project_name" {
  type        = string
  description = "name of the project"
}

variable "infra_environment" {
  type        = string
  description = "environment to be provisioned"
}