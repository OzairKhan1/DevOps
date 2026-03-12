variable "ec2_versitile_config" {
  type = map(object({
    ami_id = string
    ec2_type = string
    ec2_volume = number

  }))
 
# This approach is very versitile and we can add as many paramter as possible for uniqueness

  default = {
        dev = {
    ec2_type = "t2.small"
    ec2_volume = 8
    ami_id = "ami-0f3caa1cf4417e51b" # This si Amazon Linux ami id
   }
 
    stage = {
    ec2_type = "t2.micro"
    ec2_volume = 10
    ami_id = "ami-0b6c6ebed2801a5cb"  # This is Ubuntu ami-id
   }
      prod = {
    ec2_type = "t2.micro"
    ec2_volume = 12
    ami_id = "ami-0ad50334604831820"     # This is RedHat ami-id
   }
  }
}
