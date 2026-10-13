# VPCs in both regions. The DR VPC is deliberately separate from the primary
# VPC so a region-scoped network problem does not take down both sides.

data "aws_availability_zones" "primary" {
  state = "available"
}

data "aws_availability_zones" "dr" {
  provider = aws.dr
  state    = "available"
}

resource "aws_vpc" "primary" {
  cidr_block           = var.primary_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-primary"
  }
}

resource "aws_vpc" "dr" {
  provider = aws.dr

  cidr_block           = var.dr_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-dr"
  }
}

resource "aws_subnet" "primary" {
  count                   = 2
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = cidrsubnet(var.primary_vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.primary.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project}-primary-${count.index}"
  }
}

resource "aws_subnet" "dr" {
  provider = aws.dr

  count                   = 2
  vpc_id                  = aws_vpc.dr.id
  cidr_block              = cidrsubnet(var.dr_vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.dr.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project}-dr-${count.index}"
  }
}
