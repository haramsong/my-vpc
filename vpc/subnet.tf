resource "aws_subnet" "public_subnet" {
  count                   = var.number_of_public_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${var.vpc_prefix}.${count.index + var.number_of_vpc * 16}.0/${var.subnet_block}"
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}
resource "aws_subnet" "private_subnet" {
  count                   = var.number_of_private_subnets
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "${var.vpc_prefix}.${count.index + 10 + var.number_of_vpc * 16}.0/${var.subnet_block}"
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  }
}