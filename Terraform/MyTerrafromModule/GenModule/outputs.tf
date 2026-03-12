# Networking
output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.modInstance[*].public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.modInstance[*].public_dns
}

output "ec2_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.modInstance[*].private_ip
}

output "ec2_private_dns" {
  description = "Private DNS of the EC2 instance"
  value       = aws_instance.modInstance[*].private_dns
}

# Identity
output "ec2_instance_id" {
  description = "Instance ID of the EC2 instance"
  value       = aws_instance.modInstance[*].id
}
