# Provider version requirements
terraform {

  # backend "s3" {
  #   bucket = "tfstate873654210389"
  #   key    = "terraform_aws_vpc.tfstate"
  #   region = "eu-west-2"
  # }

  backend "remote" {
    hostname = "app.terraform.io"
    organization = "vpzen"

    workspaces {
      name = "aws-vpc-dev-eu-west2"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.39.0"
    }
  }
}

provider "aws" {
   profile    = "dan.everis.nttdata" # Configured in user credentials file
   region     = "eu-west-2"
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true 
  tags = {
    Name = "main-vpc"
  }
}

# Create 3 Private subnets, 1 in each availability zone available in eu-west-2. 
# These subnets won't have a direct route to the Internet and hence are considered "private".
# By default, they also won't assign public IP addresses to instances
# For outbound Internet connectivity, all traffic will go via a NAT Gateway in the respective AZ

resource "aws_subnet" "priv_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_priv_a_cidr
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "priv-a"
  }
}


resource "aws_subnet" "priv_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_priv_b_cidr
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "priv-b"
  }
}

resource "aws_subnet" "priv_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_priv_c_cidr
  availability_zone       = "eu-west-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "priv-c"
  }
}


# Create 3 Public subnets, 1 in each availability zone available in eu-west-2.
# These subnets have a route directly to the internet gateway and provision public IP's by default
resource "aws_subnet" "pub_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_pub_a_cidr
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-a"
  }
}

resource "aws_subnet" "pub_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_pub_b_cidr
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-b"
  }
}

resource "aws_subnet" "pub_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_pub_c_cidr
  availability_zone       = "eu-west-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "pub-c"
  }
}

# Create an Internet Gateway to get traffic out to the internet. Any resources with a Public IP in the 
# Public subnets will use this. The Internet Gateway will provide NAT for these instances, as in reality they're
# only aware of their private IP address, despite being assigned a Public address you can see in the AWS console. 
# The NAT gateway will also use this as the next hop for forwarding traffic to the Internet. 

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Create 3x NAT Gateways, one in each Public Subnet, which means it is inherently spread across all 3 AZ's on offer in eu-west-2
# Each private subnet will later have it's own routing table that points it to it's respective NAT gateway
# We'll also attach a static Elastic IP here so we can guarantee the source IP of traffic originating from resources in the VPC

resource "aws_eip" "nat_a" {
  vpc      = true
}

resource "aws_eip" "nat_b" {
  vpc      = true
}

resource "aws_eip" "nat_c" {
  vpc      = true
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.pub_a.id
  depends_on    = [aws_internet_gateway.igw] # Breaks outbound connectivity via NAT if removed
  tags = {
    Name = "natgw-a"
  }
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.pub_b.id
  depends_on    = [aws_internet_gateway.igw] # Breaks outbound connectivity via NAT if removed
  tags = {
    Name = "natgw-b"
  }
}

resource "aws_nat_gateway" "nat_c" {
  allocation_id = aws_eip.nat_c.id
  subnet_id     = aws_subnet.pub_c.id
  depends_on    = [aws_internet_gateway.igw] # Breaks outbound connectivity via NAT if removed
  tags = {
    Name = "natgw-c"
  }
}


# Create route tables
# Create 1x for each private subnet. These have to be unique as they each point to the NAT Gateway in their AZ
# All 3 public subnets can share the same generic route table, they all forward traffic to a single IGW.

# Public route table
resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt-pub"
  }
}

# Private route table A
resource "aws_route_table" "priv_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "rt-priv-a"
  }
}

# Private route table B
resource "aws_route_table" "priv_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "rt-priv-b"
  }
}

# Private route table C
resource "aws_route_table" "priv_c" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_c.id
  }

  tags = {
    Name = "rt-priv-c"
  }
}

# Associate the above routing tables to the corresponding subnets
resource "aws_route_table_association" "priv_a" {
  subnet_id      = aws_subnet.priv_a.id
  route_table_id = aws_route_table.priv_a.id
}

resource "aws_route_table_association" "priv_b" {
  subnet_id      = aws_subnet.priv_b.id
  route_table_id = aws_route_table.priv_b.id
}

resource "aws_route_table_association" "priv_c" {
  subnet_id      = aws_subnet.priv_c.id
  route_table_id = aws_route_table.priv_c.id
}

# Associate the public subnets to the same routing table that they all share
resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.pub_a.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "pub_b" {
  subnet_id      = aws_subnet.pub_b.id
  route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "pub_c" {
  subnet_id      = aws_subnet.pub_c.id
  route_table_id = aws_route_table.pub.id
}