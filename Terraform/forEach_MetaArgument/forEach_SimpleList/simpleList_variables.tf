variable "ec2_type" {
  type = list(string)
  default = [ "t2.micro", "t2.small", "t2.meduim" ]
}


#Limitation is That only 1 value is changing and we can't Change volume_type or Tags per Env with this approach
