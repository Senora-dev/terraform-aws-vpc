#--- VPC ---#
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  instance_tenancy     = var.instance_tenancy

  tags = merge(
    {
      "Name" = var.name
    },
    var.tags,
    var.vpc_tags
  )
}

#--- Internet Gateway ---#
resource "aws_internet_gateway" "this" {
  count = var.create_igw && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      "Name" = format("%s-igw", var.name)
    },
    var.tags,
    var.igw_tags
  )
}

#--- Public Subnets ---#
resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block             = var.public_subnets[count.index]
  availability_zone      = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id   = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    {
      "Name" = format("%s-public-%s", var.name, element(var.azs, count.index))
    },
    var.tags,
    var.public_subnet_tags
  )
}

#--- Private Subnets ---#
resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block             = var.private_subnets[count.index]
  availability_zone      = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id   = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null

  tags = merge(
    {
      "Name" = format("%s-private-%s", var.name, element(var.azs, count.index))
    },
    var.tags,
    var.private_subnet_tags
  )
}

#--- Database Subnets ---#
resource "aws_subnet" "database" {
  count = length(var.database_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block             = var.database_subnets[count.index]
  availability_zone      = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id   = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null

  tags = merge(
    {
      "Name" = format("%s-db-%s", var.name, element(var.azs, count.index))
    },
    var.tags,
    var.database_subnet_tags
  )
}

#--- NAT Gateways ---#
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0

  domain = "vpc"

  tags = merge(
    {
      "Name" = format("%s-nat-%s", var.name, element(var.azs, count.index))
    },
    var.tags,
    var.nat_eip_tags
  )
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0

  allocation_id = element(aws_eip.nat[*].id, count.index)
  subnet_id     = element(aws_subnet.public[*].id, count.index)

  tags = merge(
    {
      "Name" = format("%s-nat-%s", var.name, element(var.azs, count.index))
    },
    var.tags,
    var.nat_gateway_tags
  )

  depends_on = [aws_internet_gateway.this]
}

#--- Route Tables ---#
resource "aws_route_table" "public" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      "Name" = format("%s-public", var.name)
    },
    var.tags,
    var.public_route_table_tags
  )
}

resource "aws_route" "public_internet_gateway" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table" "private" {
  count = length(var.private_subnets) > 0 ? (var.single_nat_gateway ? 1 : length(var.private_subnets)) : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      "Name" = var.single_nat_gateway ? "${var.name}-private" : format("%s-private-%s", var.name, element(var.azs, count.index))
    },
    var.tags,
    var.private_route_table_tags
  )
}

resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? length(aws_route_table.private[*].id) : 0

  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, var.single_nat_gateway ? 0 : count.index)
}

resource "aws_route_table" "database" {
  count = length(var.database_subnets) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      "Name" = "${var.name}-database"
    },
    var.tags,
    var.database_route_table_tags
  )
}

#--- Route Table Associations ---#
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)

  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, var.single_nat_gateway ? 0 : count.index)
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnets)

  subnet_id      = element(aws_subnet.database[*].id, count.index)
  route_table_id = aws_route_table.database[0].id
}

#--- VPC Flow Logs ---#
resource "aws_flow_log" "this" {
  count = var.enable_flow_log ? 1 : 0

  log_destination      = var.flow_log_destination_arn
  log_destination_type = var.flow_log_destination_type
  traffic_type        = var.flow_log_traffic_type
  vpc_id              = aws_vpc.this.id
  iam_role_arn        = var.flow_log_iam_role_arn

  tags = merge(
    {
      "Name" = format("%s-flow-log", var.name)
    },
    var.tags,
    var.vpc_flow_log_tags
  )
} 