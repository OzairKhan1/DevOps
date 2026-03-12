# Different Names Based on Index (Conditional Logic)

resource "aws_s3_bucket" "demoBucket" {
  count = 3

  bucket = count.index == 0 ? "${var.env}-logs" :
           count.index == 1 ? "${var.env}-backup" :
           "${var.env}-appdata"

  tags = {
    Name = count.index == 0 ? "logs-bucket" :
           count.index == 1 ? "backup-bucket" :
           "appdata-bucket"

    Environment = var.env
  }
}
