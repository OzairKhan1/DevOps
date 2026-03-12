provider "aws" {
  region = "us-east-1"
}


# IAM Role for EC2

resource "aws_iam_role" "ec2_role" {
  name = "ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}


# Attach SSM Policy
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 cannot directly use IAM Role.It must use something called an Instance Profile. It is a container which holds the iam role
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-ssm-profile"
  role = aws_iam_role.ec2_role.name
}


resource "aws_instance" "iam_Instance" {
  ami           = "ami-0b6c6ebed2801a5cb"         # "ami-0c02fb55956c7d316" # Amazon Linux 2 (us-east-1)
  instance_type = "t2.micro"

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  tags = {
    Name = "SSM-Enabled-Instance"
  }
  user_data = file("/home/ubuntu/Terraform/Terraform-ec2-iam-ssm-secure-access/install_Ssm.sh")
}

# So the whole process is : You create a role with trust policy (which service can assume the role). 
# Attach policy to that role. (What the role can do)
# Put the role inside Container (Which is Ec2 Profile because we can directly attach a role to ec2)
# Create an Instance with that Profile Attached (iam_instance_profile = name of profile)

#Flow:  Role → Instance Profile → EC2 → STS → Temporary Credentials
