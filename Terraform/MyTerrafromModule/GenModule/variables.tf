variable "path_to_public_key" {
  description = "It is recommended to Create a key and Provide a Key Path"
  type = string
}
variable "ec2_ami_id" {
  description = "Provide you ami id. The default is ubuntu"
  default     = "ami-0b6c6ebed2801a5cb"
  type        = string
}

variable "ec2_type" {
  description = "Enter the type of instance that you want to Create. The default is t2.micro"
  default     = "t2.micro"
  type        = string
}

variable "block_storage" {
  type        = number
  description = "Just Provide volume for your ec2. The default is 8Gb"
  default     = 8
}

variable "tags" {
  description = "Custom tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "allowed_ports" {
  type        = list(number)
  description = "Add the Port number that is needed to open"
}



variable "count_number" {
  description = "Enter how many resource do you want to create. The default is 1"
  default     = 1
  type        = number

}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "role" {
  description = "Role (db,webSever)"
  type        = string
}


