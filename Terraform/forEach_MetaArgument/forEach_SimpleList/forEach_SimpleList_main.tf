resource "aws_instance" "InstanceForEach" {
  # I want to create Instances for 3 different Env. dev, stage, prd,
  # What the Problem with list is. I can only use 1 parameter. Like i can only use the ec2_type variable with for_each but what if i want
  # to have different volume_size for each Environment, like 8Gb for dev, 10Gb for stage and 20Gb for prod. i can't use with list        
  # for that i have to use map object so for each have 2 values
  for_each = toset(var.ec2_type)

  instance_type          = each.value
  ami                    = "ami-0b6c6ebed2801a5cb"
  key_name               = "terraformKey"
  vpc_security_group_ids = ["sg-00892a12fe4421493"]
  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }
  tags = {
    Environment = "General"
  }


}


# This was use to create s3 bucket. The main error was naming convention for s3 
#which is alwasy small letter


# resource "aws_s3_bucket" "demoBucket" {
#   count  = 2
#   bucket = "${var.env}-demobucket-${count.index + 1}-ozairkhan"
#   tags = {
#     Name        = "${var.env}-demoBucket-${count.index + 1}"   
#     Environment = var.env
#   }
# }
