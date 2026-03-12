terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.35.1"
    }
  }
}

# -------------------------
# Providers for each region
# -------------------------
provider "aws" {
  alias  = "us-east-1"      # alias is used as identifier for each Regions
  region = "us-east-1"
}

provider "aws" {
  alias  = "us-east-2"
  region = "us-east-2"
}

# -------------------------
# AMI data for each region
# -------------------------
data "aws_ami" "ubuntu_us_east_1" {
  provider    = aws.us-east-1
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_ami" "ubuntu_us_east_2" {
  provider    = aws.us-east-2
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# -------------------------
# EC2 Instances
# -------------------------
resource "aws_instance" "Region_1_Instance" {
  ami           = data.aws_ami.ubuntu_us_east_1.id
  instance_type = "t2.micro"
  provider      = aws.us-east-1

  tags = {
    Name = "Multi_Regional_Instance_US_EAST_1"
  }
}

resource "aws_instance" "Region_2_Instance" {
  ami           = data.aws_ami.ubuntu_us_east_2.id
  instance_type = "t2.micro"
  provider      = aws.us-east-2

  tags = {
    Name = "Multi_Regional_Instance_US_EAST_2"
  }
}
