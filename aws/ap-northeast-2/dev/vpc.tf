
# Private subnets (conditional based on environment)
resource "aws_subnet" "private" {
  count = local.current_config.enable_nat_gateway ? local.subnet_count : 0
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Type = "Private"
  })
}

# NAT Gateway (production only)
resource "aws_eip" "nat" {
  count  = local.current_config.enable_nat_gateway ? 1 : 0
  domain = "vpc"
  
  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  })
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = local.current_config.enable_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  
  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-nat-gw"
  })
  
  depends_on = [aws_internet_gateway.main]
}

# Private route table (conditional)
resource "aws_route_table" "private" {
  count  = local.current_config.enable_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }
  
  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt"
  })
}

# Private route table associations (conditional)
resource "aws_route_table_association" "private" {
  count          = local.current_config.enable_nat_gateway ? length(aws_subnet.private) : 0
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}



resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# Public subnets (only 2 for cost optimization)
resource "aws_subnet" "public" {
  count = 2
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    Type = "Public"
  })
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  # Explicit dependency: Ensure IGW is attached before creating routes
  depends_on = [aws_internet_gateway.main]
  
  tags = merge(var.default_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
  
  # Explicit dependency: Ensure route table and subnets exist
  depends_on = [
    aws_route_table.public,
    aws_subnet.public
  ]
}