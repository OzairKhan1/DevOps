# Notes:: Only Replace  "myInstance" by the name of "Ec2-Instance" that user has define for their ec2. All the names after output block are User define. 
# The Output are saved in the variable " value " 

# Instance ID
output "ec2_instance_id" {
  value = aws_instance.myInstance.id
}
 
# Instance Type
output "ec2_instance_type" {
  value = aws_instance.myInstance.instance_type
}

# Public IP
output "ec2_public_ip" {
  value = aws_instance.myInstance.public_ip
}

# Private IP
output "ec2_private_ip" {
  value = aws_instance.myInstance.private_ip
}

# Public DNS
output "ec2_public_dns" {
  value = aws_instance.myInstance.public_dns
}

# Availability Zone
output "ec2_availability_zone" {
  value = aws_instance.myInstance.availability_zone
}

# Region (comes from provider data, not instance directly)
output "ec2_region" {
  value = data.aws_region.current.name
}

# AMI ID
output "ec2_ami_id" {
  value = aws_instance.myInstance.ami
}

# State (requires aws_instance state attribute from data source)
output "ec2_state" {
  value = aws_instance.myInstance.instance_state
}

# Launch Time
output "ec2_launch_time" {
  value = aws_instance.myInstance.launch_time
}

# Key Pair Name
output "ec2_key_name" {
  value = aws_instance.myInstance.key_name
}

# Security Groups
output "ec2_security_groups" {
  value = aws_instance.myInstance.vpc_security_group_ids
}

# Subnet ID
output "ec2_subnet_id" {
  value = aws_instance.myInstance.subnet_id
}

# VPC ID (comes from subnet or instance attribute)
output "ec2_vpc_id" {
  value = aws_instance.myInstance.vpc_security_group_ids[0]
}

# IAM Role / Instance Profile
output "ec2_iam_instance_profile" {
  value = aws_instance.myInstance.iam_instance_profile
}

# Root Volume ID
output "ec2_root_volume_id" {
  value = aws_instance.myInstance.root_block_device[0].volume_id
}

# Root Volume Size
output "ec2_root_volume_size" {
  value = aws_instance.myInstance.root_block_device[0].volume_size
}

# Additional EBS Volumes (list)
output "ec2_ebs_volumes" {
  value = aws_instance.myInstance.ebs_block_device[*].volume_id
}

# Tags
output "ec2_tags" {
  value = aws_instance.myInstance.tags
}

# Elastic IP (if associated separately via aws_eip resource)
output "ec2_elastic_ip" {
  value = aws_eip.myInstance.public_ip
}
