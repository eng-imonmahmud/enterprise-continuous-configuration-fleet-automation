module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  environment  = var.environment
}

module "ec2" {
  source               = "./modules/ec2"
  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  subnet_id            = module.vpc.private_subnet_id
  iam_instance_profile = module.iam.instance_profile_name
}

module "ssm" {
  source       = "./modules/ssm"
  project_name = var.project_name
  environment  = var.environment
  owner        = var.owner
  instance_id  = module.ec2.instance_id
}
