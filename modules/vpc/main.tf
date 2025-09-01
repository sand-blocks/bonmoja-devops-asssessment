module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.0.1"


  name = "${var.project_name}-${var.infra_environment}-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = true ## CM Done for cost optimization
  one_nat_gateway_per_az = false

  tags = {
    Terraform   = "true"
    Environment = var.infra_environment
    Project     = var.project_name
  }
}

