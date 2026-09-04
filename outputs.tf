output "ec2_instance_id" {
  value = aws_instance.app.id
}

output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}

output "ec2_public_dns" {
  value = aws_instance.app.public_dns
}

output "eip_public_ip" {
  value = aws_eip.app_eip.public_ip
}

output "default_domain" {
  value       = aws_instance.app.public_dns
  description = "Default domain (via nip.io) that resolves to the allocated Elastic IP"
}

output "rds_endpoint" {
  value = aws_db_instance.default.address
}

output "rds_port" {
  value = aws_db_instance.default.port
}

output "rds_database_name" {
  value = aws_db_instance.default.db_name
}

output "ssh_command" {
  value = "ssh -i ./petclinic.pem ubuntu@${aws_eip.app_eip.public_ip}"
}
