module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  
  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr
  
  azs             = var.azs
  private_subnets = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnets  = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 4, i + length(var.azs))]
  
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  
  enable_vpn_gateway = true
  
  enable_dns_hostnames = true
  enable_dns_support   = true
}