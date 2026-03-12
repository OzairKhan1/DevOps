resource "aws_instance" "forEachMapObj" {
  for_each = var.ec2_versitile_config
  key_name = "terraformKey"
  vpc_security_group_ids = ["sg-00892a12fe4421493"]
  instance_type = each.value.ec2_type
  ami = each.value.ami_id
  root_block_device{
    volume_size = each.value.ec2_volume
    volume_type = "gp3"
    encrypted = true
  }

  tags =  {
    Environment = each.key

  }
  
}
