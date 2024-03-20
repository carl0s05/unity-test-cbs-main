# Retrieves the current AWS region information to use in other resources as needed.
data "aws_region" "current" {}

# Local values for easy management of CIDR blocks across different environments are in mappings.tf

# Data source: aws_ec2_transit_gateway
# Retrieves information about a specific EC2 Transit Gateway based on filtering criteria.
# you need to reference a Transit Gateway that belongs to a specific AWS account.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ec2_transit_gateway

data "aws_ec2_transit_gateway" "local" {
  filter {
    name   = "owner-id"
    values = [local.network_base[var.environment]["tgw"]]
  }
}

# Resource: aws_ec2_transit_gateway_vpc_attachment
# Creates a VPC attachment for an EC2 Transit Gateway, enabling the connection between the Transit Gateway
# and a specified VPC. This setup is crucial for extending your network's architecture, allowing the VPC to communicate with other connected networks via the Transit Gateway.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment

resource "aws_ec2_transit_gateway_vpc_attachment" "corp_attachment" {
  subnet_ids         = [aws_subnet.priv_subnet["eks-a"].id, aws_subnet.priv_subnet["eks-b"].id, aws_subnet.priv_subnet["eks-c"].id]
  transit_gateway_id = data.aws_ec2_transit_gateway.local.id
  vpc_id             = aws_vpc.vpc.id
}

# Resource: aws_vpc
# This resource creates a Virtual Private Cloud (VPC) to provide a logically isolated section of the AWS cloud where you can launch AWS resources.
# A VPC gives you control over your virtual networking environment, including selection of your IP address range, creation of subnets, and configuration of route tables and network gateways.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc

resource "aws_vpc" "vpc" {
  #checkov:skip=CKV2_AWS_11:Flow Logs configuration is not yet defined
  cidr_block           = local.network_base[var.environment]["vpc"]
  enable_dns_hostnames = true
  enable_dns_support   = true
  #tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
  tags = {
    Name =join ( "-", [local.prefix,"vpc",local.project, var.appname, var.environment])
  }
}

resource "aws_route_table_association" "rt_assoc" {
  for_each = local.network["associaton"]
  route_table_id = aws_route_table.priv_rt[each.value].id
  subnet_id = aws_subnet.priv_subnet[each.key].id
}

# Resource: aws_default_security_group
# Manages the default security group for the specified VPC, disable connectivity on default security group.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id
}

# Resource: aws_vpc_ipv4_cidr_block_association
# It associates an additional IPv4 CIDR block with an existing VPC.
# It's useful for extending the IP address range of your VPC when you need more subnets or want to organize resources with different CIDR blocks.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipv4_cidr_block_association

resource "aws_vpc_ipv4_cidr_block_association" "vpc_cidr_block2" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = local.network_base[var.environment]["iso"]
}

# Resource: aws_subnet
# Subnets allow you to partition your VPC into separate sections, each can be located in a different availability zone for high availability and fault tolerance.
# For more info, visit: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

resource "aws_subnet" "priv_subnet" {
    for_each = local.network["subnet"]
    vpc_id = aws_vpc.vpc.id
    cidr_block = each.value
    map_public_ip_on_launch = false
    availability_zone = join("",[data.aws_region.current.id,substr(each.key, -1, -1)])
    tags = {
        Name = join("-",[local.prefix,"subnet-priv",var.appname,var.environment,each.key])
    }
}

# Resource: aws_route_table
# Defines rules for routing traffic from subnets to destinations, such as an internet gateway.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table

resource "aws_route_table" "priv_rt" {
  for_each = toset(local.network["route_table"])
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = join ( "-", [local.prefix,"rtbl-priv",local.project,var.environment,var.appname, each.value ])
  }
}

# Resource: aws_route
# Defines a routing rule for a specified route table, directing traffic from the subnet to a specified gateway, NAT instance, VPC peering connection, or network interface.
# This is crucial for defining how traffic is routed in and out of subnets within a VPC, ensuring that resources have the appropriate access to local networks or the internet.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route

resource "aws_route" "private_route" {
  for_each = local.network["routes_tgw"]
  route_table_id         = aws_route_table.priv_rt[each.key].id
  destination_cidr_block = each.value
  transit_gateway_id     = data.aws_ec2_transit_gateway.local.id
  depends_on             = [aws_ec2_transit_gateway_vpc_attachment.corp_attachment]
}

# Resource: aws_subnet
# Subnets allow you to partition your VPC into separate sections, each can be located in a different availability zone for high availability and fault tolerance.
# For more info, visit: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet

resource "aws_subnet" "iso_subnet" {
  for_each = local.network["iso_subnet"]
  cidr_block              = each.value
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = join("",[data.aws_region.current.id,substr(each.key, -1, -1)])
  map_public_ip_on_launch = false
  tags = {
    Name = join("-",[local.prefix,"subnet-priv",var.appname,var.environment,each.key])
  }
  depends_on = [aws_vpc_ipv4_cidr_block_association.vpc_cidr_block2]
}

# The SCP Permissions does not allow the creation of NAT Gateway, the next elements should be commented, as they will trigger errors
# Lines: [128-170] Please note without NAT Gateway and Internet, NodeGroup won't come up. If manually, please create before 

# Resource: aws_nat_gateway
# Provides outbound internet access to resources in a private subnet by translating their private IP addresses to a public IP address.
# Highly recommended for allowing private resources to access the internet securely without being directly accessible from the internet.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway

resource "aws_nat_gateway" "priv_nat_gw" {
  connectivity_type = "private"
  subnet_id     = aws_subnet.priv_subnet["alb-a"].id
}

# Resource: aws_route_table
# Defines rules for routing traffic from subnets to destinations, such as an internet gateway.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table

resource "aws_route_table" "isolated_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = join("-",[local.prefix,"rtbl-priv",var.appname,var.environment,"eks-nodes"])
  }
}

# Resource: aws_route
# Defines a routing rule for a specified route table, directing traffic from the subnet to a specified gateway, NAT instance, VPC peering connection, or network interface.
# This is crucial for defining how traffic is routed in and out of subnets within a VPC, ensuring that resources have the appropriate access to local networks or the internet.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route

resource "aws_route" "isolated_route" {
  route_table_id = aws_route_table.isolated_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.priv_nat_gw.id
  depends_on = [aws_ec2_transit_gateway_vpc_attachment.corp_attachment]
}

# Resource: aws_route_table_association
# Associates a subnet with a specific route table, allowing you to define custom routing rules for each subnet.
# This is important for directing traffic from your subnets through intended paths, such as an internet gateway or a NAT gateway.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association

resource "aws_route_table_association" "isolated_route_table_association" {
  for_each = local.network["iso_subnet"]
  route_table_id = aws_route_table.isolated_route_table.id
  subnet_id      = aws_subnet.iso_subnet[each.key].id
}

# Resource: aws_security_group
# Defines a security group for controlling access to resources within your VPC. It acts as a virtual firewall.
# Security groups are crucial for defining inbound and outbound traffic rules to secure your resources.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

resource "aws_security_group" "db_yugabyte_nodo" {
  name        = join("-",[local.prefix,"sg",var.appname,var.environment,"yugabyte-nodes"])
  description = "Yugabyte Nodo Security Group"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 9090
    to_port     = 9090
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 80
    to_port     = 80
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 443
    to_port     = 443
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 6379
    to_port     = 6379
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 13000
    to_port     = 13000
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 9070
    to_port     = 9070
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 5433
    to_port     = 5433
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 18018
    to_port     = 18018
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 7100
    to_port     = 7100
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 22
    to_port     = 22
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 54422
    to_port     = 54422
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 12000
    to_port     = 12000
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 7000
    to_port     = 7000
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 11000
    to_port     = 11000
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 9042
    to_port     = 9042
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 9100
    to_port     = 9100
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 9000
    to_port     = 9000
  }

  ingress {
    description = "Private Yugabyte Web Access"
    cidr_blocks = [var.mgmt_vpc_cidr_access, aws_vpc.vpc.cidr_block]
    protocol    = "TCP"
    from_port   = 9300
    to_port     = 9300
  }

  egress {
    description = "Outbound Internet Access HTTPS"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = {
    Name = join("-",[local.prefix,"sg",var.appname,var.environment,"yugabyte-nodes"])
  }
}

# Resource: aws_vpc_endpoint
# Creates a VPC endpoint for AWS Services, allowing private access to service resources without requiring an internet gateway, NAT device, VPN connection, or AWS Direct Connect connection.
# VPC endpoints are crucial for secure and private communication between AWS services and your VPC.
# This example specifically creates an S3 VPC endpoint, enabling private access to S3 buckets from within the VPC.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint

resource "aws_vpc_endpoint" "s3_gw_endpoint" {
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.priv_rt["priv-eks"].id,
    aws_route_table.isolated_route_table.id,
  ]
  vpc_id = aws_vpc.vpc.id
}

