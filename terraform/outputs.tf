output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "instance_id" {
  description = "ID of the EC2 Instance"
  value       = module.ec2.instance_id
}
