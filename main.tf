# retrieves the availability zones from the specified region (see provider)
data "aws_availability_zones" "available" {}

locals {
  # elastic ip addresses - this should correspond with the number of
  # public subnets specified in `var.public_subnets`.
  eip_count = 3
  cidr_ip   = regex("[0-9]+.[0-9]+.[0-9]+.[0-9]+", length(var.secondary_cidr_blocks) > 0 ? var.secondary_cidr_blocks[0] : var.vpc_cidr)

  tags = var.cidr_name != "" ? { CIDR_NAME = var.cidr_name } : {}

  az_names = slice(data.aws_availability_zones.available.names, 0, var.number_of_azs)

  vpc_tags = merge(var.vpc_tags)

  vpc_flow_log_name_chunks = split(":", module.vpc.vpc_flow_log_destination_arn)
  vpc_flow_log_name        = local.vpc_flow_log_name_chunks[length(local.vpc_flow_log_name_chunks) - 1]
}

# creates the elastic IPs which the NAT gateways are allocated
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? local.eip_count : 0

  domain = "vpc"
  tags   = merge(var.tags, local.tags, var.folder)
}

# virtual private cloud creator
module "vpc" {
  source = "github.com/GovTechSG/terraform-aws-vpc-forked?ref=v4.0.6"

  # meta data
  name                  = var.vpc_name
  cidr                  = var.vpc_cidr
  cidr_name             = var.cidr_name
  secondary_cidr_blocks = var.secondary_cidr_blocks

  # availability & network topology
  azs            = local.az_names
  public_subnets = var.public_subnets

  public_subnet_tags = merge(
    var.eks_cluster_tags,
    var.eks_public_subnet_tags,
    {
      "kubernetes.io/role/elb" = "1",
      "AccessType"             = "internet ingress/egress"
    }
  )

  public_route_table_tags = {
    "AccessType" = "internet ingress/egress"
  }

  firewall_subnets               = var.firewall_subnets
  firewall_sync_states           = var.firewall_sync_states
  firewall_dedicated_network_acl = var.firewall_dedicated_network_acl
  firewall_inbound_acl_rules     = var.firewall_inbound_acl_rules
  firewall_outbound_acl_rules    = var.firewall_outbound_acl_rules

  public_dedicated_network_acl = var.public_dedicated_network_acl
  public_inbound_acl_rules     = var.public_inbound_acl_rules
  public_outbound_acl_rules    = var.public_outbound_acl_rules

  private_dedicated_network_acl = var.private_dedicated_network_acl
  private_inbound_acl_rules     = var.private_inbound_acl_rules
  private_outbound_acl_rules    = var.private_outbound_acl_rules

  intra_dedicated_network_acl = var.intra_dedicated_network_acl
  intra_inbound_acl_rules     = var.intra_inbound_acl_rules
  intra_outbound_acl_rules    = var.intra_outbound_acl_rules

  database_dedicated_network_acl = var.database_dedicated_network_acl
  database_inbound_acl_rules     = var.database_inbound_acl_rules
  database_outbound_acl_rules    = var.database_outbound_acl_rules

  private_subnets = var.private_subnets

  private_subnet_tags = merge(
    var.eks_cluster_tags,
    var.eks_private_subnet_tags,
    {
      "kubernetes.io/role/internal-elb" = "1",
      "AccessType"                      = "internet egress"
    }
  )

  private_route_table_tags = {
    "AccessType" = "internet egress"
  }

  intra_subnets = var.intranet_subnets

  intra_subnet_tags = merge(
    var.eks_cluster_tags,
    var.eks_intra_subnet_tags,
    {
      "AccessType" = "intranet"
    }
  )

  intra_route_table_tags = {
    "AccessType" = "intranet"
  }

  database_subnets = var.database_subnets

  database_subnet_tags = {
    "AccessType" = "database"
  }

  database_route_table_tags = {
    "AccessType" = "database"
  }

  # nat stuff
  enable_nat_gateway                 = var.enable_nat_gateway
  single_nat_gateway                 = false
  one_nat_gateway_per_az             = true
  reuse_nat_ips                      = true
  create_database_subnet_route_table = true
  external_nat_ip_ids                = aws_eip.nat.*.id

  # service discovery stuff
  enable_dns_hostnames = true

  # nacl
  manage_default_network_acl  = var.manage_default_network_acl
  default_network_acl_name    = var.default_network_acl_name
  default_network_acl_tags    = var.default_network_acl_tags
  default_network_acl_ingress = var.default_network_acl_ingress
  default_network_acl_egress  = var.default_network_acl_egress

  # others
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags                    = merge(var.tags, local.vpc_tags)

  manage_default_vpc               = var.manage_default_vpc
  default_vpc_tags                 = var.default_vpc_tags
  default_vpc_name                 = var.default_vpc_name
  default_vpc_enable_dns_support   = var.default_vpc_enable_dns_support
  default_vpc_enable_dns_hostnames = var.default_vpc_enable_dns_hostnames

  manage_default_security_group  = var.manage_default_security_group
  default_security_group_name    = var.default_security_group_name
  default_security_group_ingress = var.default_security_group_ingress
  default_security_group_egress  = var.default_security_group_egress
  default_security_group_tags    = var.default_security_group_tags

  manage_default_route_table           = var.manage_default_route_table
  default_route_table_name             = var.default_route_table_name
  default_route_table_propagating_vgws = var.default_route_table_propagating_vgws
  default_route_table_routes           = var.default_route_table_routes
  default_route_table_tags             = var.default_route_table_tags

  # flow log
  enable_flow_log                                 = var.enable_flow_log
  vpc_flow_log_permissions_boundary               = var.vpc_flow_log_permissions_boundary
  flow_log_max_aggregation_interval               = var.flow_log_max_aggregation_interval
  flow_log_traffic_type                           = var.flow_log_traffic_type
  flow_log_destination_type                       = var.flow_log_destination_type
  flow_log_log_format                             = var.flow_log_log_format
  flow_log_destination_arn                        = var.flow_log_destination_arn
  flow_log_file_format                            = var.flow_log_file_format
  flow_log_hive_compatible_partitions             = var.flow_log_hive_compatible_partitions
  flow_log_per_hour_partition                     = var.flow_log_per_hour_partition
  vpc_flow_log_tags                               = var.vpc_flow_log_tags
  create_flow_log_cloudwatch_log_group            = var.create_flow_log_cloudwatch_log_group
  create_flow_log_cloudwatch_iam_role             = var.create_flow_log_cloudwatch_iam_role
  flow_log_cloudwatch_iam_role_arn                = var.flow_log_cloudwatch_iam_role_arn
  flow_log_cloudwatch_log_group_name_prefix       = var.flow_log_cloudwatch_log_group_name_prefix
  flow_log_cloudwatch_log_group_name_suffix       = var.flow_log_cloudwatch_log_group_name_suffix
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_cloudwatch_log_group_retention_in_days
  flow_log_cloudwatch_log_group_kms_key_id        = var.flow_log_cloudwatch_log_group_kms_key_id
}

#######################
# Security Groups
#######################
resource "aws_security_group" "allow_443" {
  count = var.create_allow_443_security_group ? 1 : 0

  name        = "${var.vpc_name}-${local.cidr_ip}-allow-443"
  description = "Allow port 443 traffic to and from VPC cidr range"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = length(var.secondary_cidr_blocks) > 0 ? var.secondary_cidr_blocks : [var.vpc_cidr]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = length(var.secondary_cidr_blocks) > 0 ? var.secondary_cidr_blocks : [var.vpc_cidr]
  }

  tags = {
    Name = "Allow 443 from VPC CIDR"
  }
}

resource "aws_security_group" "allow_http_https_outgoing" {
  count = var.create_allow_http_https_outgoing_security_group ? 1 : 0

  name        = "${var.vpc_name}-${local.cidr_ip}-allow-http-https-outgoing"
  description = "Allow port all HTTP(S) traffic outgoing"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow HTTP/HTTPS Outgoing"
  }
}

#######################
# Flow Logs
#######################

resource "aws_cloudwatch_log_subscription_filter" "flow_log" {
  for_each        = var.create_flow_log_cloudwatch_log_group ? var.lg_filters : {}
  name            = "${local.vpc_flow_log_name}-${each.value.naming_suffix}"
  role_arn        = each.value.role_arn
  log_group_name  = local.vpc_flow_log_name
  filter_pattern  = each.value.filter_pattern
  destination_arn = each.value.destination_arn
  distribution    = each.value.distribution
}
