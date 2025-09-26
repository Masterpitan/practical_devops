output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.app_alb.dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.appdb.endpoint
}
/*
output "rds_password" {
  description = "RDS random password (sensitive, printed by Terraform outputs)"
  value       = random_password.rds_password.result
  sensitive   = true
}
*/
output "vpc_id" {
  value = aws_vpc.this.id
}
output "bastion_public_ip" {
  description = "Bastion host public IP"
  value       = aws_instance.bastion.public_ip
}
