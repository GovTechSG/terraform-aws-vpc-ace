terraform {
  backend "s3" {}
  required_version = "~> 0.12.0"
}

provider "aws" {
  version = "~> 2.25.0"
  region  = var.aws_region
}

# retrieves the availability zones from the specified region (see provider)
data "aws_availability_zones" "available" {}

locals {
  # elastic ip addresses - this should correspond with the number of
  # public subnets specified in `var.public_subnets`.
  eip_count         = 3
  manage_cidr_block = var.manage_cidr_block != "" ? var.manage_cidr_block : var.vpc_cidr
  cidr_ip           = regex("[0-9]+.[0-9]+.[0-9]+.[0-9]+", local.manage_cidr_block)
  # public subnets (internet access)
  public_subnets = [
    for num in var.public_subnet_net_nums :
    "${cidrsubnet(local.manage_cidr_block, lookup(var.public_new_bits, var.public_subnet_new_bits_size), num)}"
  ]

  # private subnets (internet egress only)
  private_subnets = [
    for num in var.private_subnet_net_nums :
    "${cidrsubnet(local.manage_cidr_block, lookup(var.private_new_bits, var.private_subnet_new_bits_size), num)}"
  ]

  secondary_private_subnets = [
    for num in var.secondary_private_subnet_net_nums :
    "${cidrsubnet(local.manage_cidr_block, lookup(var.private_new_bits, var.secondary_private_subnet_new_bits_size), num)}"
  ]

  database_subnets = [
    for num in var.database_subnet_net_nums :
    "${cidrsubnet(local.manage_cidr_block, lookup(var.database_new_bits, var.database_subnet_new_bits_size), num)}"
  ]

  # intra subnets (no internet access)
  intra_subnets = [
    for num in var.intranet_subnet_net_nums :
    "${cidrsubnet(local.manage_cidr_block, lookup(var.intranet_new_bits, var.intranet_subnet_new_bits_size), num)}"
  ]

  tags = var.cidr_name != "" ? { CIDR_NAME = var.cidr_name } : {}

  az_names = slice(data.aws_availability_zones.available.names, 0, var.number_of_azs)

  # vpc_tags = merge(var.vpc_tags, local.tags,var.eks_cluster_tags, { VPC = "${var.vpc_name}-${local.cidr_ip}" })
  vpc_tags = merge(var.vpc_tags)
}

# creates the elastic IPs which the NAT gateways are allocated
resource "aws_eip" "nat" {
  count = "${local.eip_count}"

  vpc  = true
  tags = "${merge(var.tags, local.tags, var.folder)}"
}

# virtual private cloud creator
module "vpc" {
  //source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v2.7.0"
  source = "github.com/GovTechSG/terraform-aws-vpc-forked?ref=v2.7.0-cidr.1"

  # meta data
  name                  = var.vpc_name
  cidr                  = var.vpc_cidr
  cidr_name             = var.cidr_name
  secondary_cidr_blocks = var.secondary_cidr_blocks

  # availability & network topology
  azs            = local.az_names
  public_subnets = local.public_subnets

  public_subnet_tags = "${merge(
    var.eks_cluster_tags,
    {
      "kubernetes.io/role/elb" = "1",
      "AccessType"             = "internet ingress/egress"
    }
  )}"

  public_route_table_tags = {
    "AccessType" = "internet ingress/egress"
  }

  private_subnets = concat(local.private_subnets, local.secondary_private_subnets)

  private_subnet_tags = "${merge(
    var.eks_cluster_tags,
    {
      "kubernetes.io/role/internal-elb" = "1",
      "AccessType"                      = "internet egress"
    }
  )}"

  private_route_table_tags = {
    "AccessType" = "internet egress"
  }

  intra_subnets = "${local.intra_subnets}"

  intra_subnet_tags = "${merge(
    var.eks_cluster_tags,
    {
      "AccessType" = "intranet"
    }
  )}"

  intra_route_table_tags = {
    "AccessType" = "intranet"
  }

  database_subnets = "${local.database_subnets}"

  database_subnet_tags = {
    "AccessType" = "database"
  }

  database_route_table_tags = {
    "AccessType" = "database"
  }

  # nat stuff
  enable_nat_gateway                 = true
  single_nat_gateway                 = false
  one_nat_gateway_per_az             = true
  reuse_nat_ips                      = true
  create_database_subnet_route_table = true
  external_nat_ip_ids                = "${aws_eip.nat.*.id}"

  # external services
  enable_s3_endpoint = var.enable_s3_endpoint

  # service discovery stuff
  enable_dns_hostnames = true

  # others
  #  tags = merge(var.tags, var.folder, local.vpc_tags)
  tags = merge(var.tags, local.vpc_tags)
}

#######################
# VPC Endpoint for EC2
#######################
data "aws_vpc_endpoint_service" "ec2" {
  service = "ec2"
}

data "aws_subnet" "private_subnet_by_az" {
  count      = length(local.az_names)
  cidr_block = element(module.vpc.private_subnets_cidr_blocks, count.index)
  depends_on = [module.vpc]
}

resource "aws_vpc_endpoint" "ec2" {
  count = var.create_private_endpoints ? 1 : 0
  vpc_id            = module.vpc.vpc_id
  service_name      = data.aws_vpc_endpoint_service.ec2.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = [aws_security_group.allow_443.id]
  subnet_ids          = distinct(concat(data.aws_subnet.private_subnet_by_az.*.id, var.private_subnet_per_az_for_private_endpoints))
  private_dns_enabled = true
  //  var.ec2_endpoint_private_dns_enabled
}

###########################
# VPC Endpoint for ECR API
###########################
data "aws_vpc_endpoint_service" "ecr_api" {
  service = "ecr.api"
}

resource "aws_vpc_endpoint" "ecr_api" {
  count = var.create_private_endpoints ? 1 : 0
  vpc_id            = module.vpc.vpc_id
  service_name      = data.aws_vpc_endpoint_service.ecr_api.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = [aws_security_group.allow_443.id]
  subnet_ids          = distinct(concat(data.aws_subnet.private_subnet_by_az.*.id, var.private_subnet_per_az_for_private_endpoints))
  private_dns_enabled = true
}

###########################
# VPC Endpoint for ECR DKR
###########################
data "aws_vpc_endpoint_service" "ecr_dkr" {
  service = "ecr.dkr"
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count = var.create_private_endpoints ? 1 : 0
  vpc_id            = module.vpc.vpc_id
  service_name      = data.aws_vpc_endpoint_service.ecr_dkr.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = [aws_security_group.allow_443.id]
  subnet_ids          = distinct(concat(data.aws_subnet.private_subnet_by_az.*.id, var.private_subnet_per_az_for_private_endpoints))
  private_dns_enabled = true
}

resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id
  tags   = merge(var.tags, local.tags, var.folder)
}

resource "aws_security_group" "allow_443" {
  name        = "${var.vpc_name}-${local.cidr_ip}-allow-443"
  description = "Allow port 443 traffic to and from VPC cidr range"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.manage_cidr_block]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.manage_cidr_block]
  }

  tags = {
    Name = "Allow 443 from VPC CIDR"
  }
}

resource "aws_security_group" "allow_http_https_outgoing" {
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

# override default network acl
resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${tolist(data.aws_network_acls.default.ids)[0]}"

  tags = "${merge({ "Name" = "${var.vpc_name}-${local.cidr_ip}-default" }, var.tags, local.tags, var.folder)}"
  lifecycle {
    ignore_changes = ["subnet_ids"]
  }
}

data "aws_network_acls" "default" {
  vpc_id = "${module.vpc.vpc_id}"

  filter {
    name   = "default"
    values = ["true"]
  }
}

resource "aws_network_acl" "private" {
  vpc_id     = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.private_subnets}"
  tags       = "${merge({ "Name" = "${var.vpc_name}-${local.cidr_ip}-private" }, var.tags, local.tags, var.folder)}"
}

resource "aws_network_acl" "public" {
  vpc_id     = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.public_subnets}"
  tags       = "${merge({ "Name" = "${var.vpc_name}-${local.cidr_ip}-public" }, var.tags, local.tags, var.folder)}"
}

resource "aws_network_acl" "intra" {
  vpc_id     = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.intra_subnets}"
  tags       = "${merge({ "Name" = "${var.vpc_name}-${local.cidr_ip}-intra" }, var.tags, local.tags, var.folder)}"
}

resource "aws_network_acl" "database" {
  vpc_id     = "${module.vpc.vpc_id}"
  subnet_ids = "${module.vpc.database_subnets}"
  tags       = "${merge({ "Name" = "${var.vpc_name}-${local.cidr_ip}-database" }, var.tags, local.tags, var.folder)}"
}


###########################
# Public subnet ACL
###########################

resource "aws_network_acl_rule" "public_inbound_allow_all_rule" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 140
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "public_outbound_allow_all_rule" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 140
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "public_inbound_ssh_rule_deny" {
  network_acl_id = "${aws_network_acl.public.id}"
  cidr_block     = "0.0.0.0/0"
  rule_number    = 139
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "public_outbound_ssh_rule_deny" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 139
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "public_inbound_rdp_rule_deny" {
  network_acl_id = "${aws_network_acl.public.id}"
  cidr_block     = "0.0.0.0/0"
  rule_number    = 105
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "public_outbound_rdp_rule_deny" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 105
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "public_inbound_ssh_rule" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 120
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "public_outbound_ssh_rule" {
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 120
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "public_inbound_ssh_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 121 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "public_outbound_ssh_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.public.id}"
  rule_number    = 121 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  egress         = true
}

###########################
# Private subnet ACL
###########################
resource "aws_network_acl_rule" "private_inbound_allow_80_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 109
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 80
  to_port        = 80
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_80_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 109
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 80
  to_port        = 80
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_allow_443_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 110
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_443_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 110
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_nfs_111_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 115
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "all"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_nfs_111_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 115
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "all"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_nfs_111_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 116 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "all"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_nfs_111_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 116 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "all"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_ssh_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 120
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_ssh_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 120
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_ssh_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 121 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_ssh_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 121 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_ssh_rule_deny" {
  network_acl_id = "${aws_network_acl.private.id}"
  cidr_block     = "0.0.0.0/0"
  rule_number    = 139
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "private_outbound_ssh_rule_deny" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 139
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_rdp_rule_deny" {
  network_acl_id = "${aws_network_acl.private.id}"
  cidr_block     = "0.0.0.0/0"
  rule_number    = 105
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "private_outbound_rdp_rule_deny" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 105
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_ldap_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 125
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 389
  to_port        = 389
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_ldap_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 125
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 389
  to_port        = 389
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_ldap_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 126 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 389
  to_port        = 389
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_ldap_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 126 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 389
  to_port        = 389
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_openvpn_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 135
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 943
  to_port        = 943
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_openvpn_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 135
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 943
  to_port        = 943
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_openvpn_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 136 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 943
  to_port        = 943
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_openvpn_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 136 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 943
  to_port        = 943
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_allow_all_ephemeral_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 140
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_all_ephemeral_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 140
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_allow_all_udp" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 141
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_all_udp" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 141
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_allow_all_udp_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 142 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_all_udp_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 142 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_allow_udp_openvpn" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 145
  cidr_block     = "0.0.0.0/0"
  protocol       = "udp"
  from_port      = 1194
  to_port        = 1194
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_udp_openvpn" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 145
  cidr_block     = "0.0.0.0/0"
  protocol       = "udp"
  from_port      = 1194
  to_port        = 1194
  rule_action    = "allow"
  egress         = "true"
}

###########################
# Intranet subnet ACL
###########################

resource "aws_network_acl_rule" "intra_inbound_rdp_rule_deny" {
  network_acl_id = "${aws_network_acl.intra.id}"
  cidr_block     = "0.0.0.0/0"
  rule_number    = 105
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "intra_outbound_rdp_rule_deny" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 105
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "intranet_inbound_allow_443_rule" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 110
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_allow_443_rule" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 110
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "intranet_inbound_ssh_rule" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 120
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_ssh_rule" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 120
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "intranet_inbound_nfs_111_rule" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 115
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "all"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_nfs_111_rule" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 115
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "all"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "intranet_inbound_nfs_111_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 116 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "all"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_nfs_111_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 116 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "all"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "intranet_inbound_ssh_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 121 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_ssh_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 121 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "intra_inbound_ssh_rule_deny" {
  network_acl_id = "${aws_network_acl.intra.id}"
  cidr_block     = "0.0.0.0/0"
  rule_number    = 139
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "intra_outbound_ssh_rule_deny" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 139
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "intra_inbound_allow_all_ephemeral_rule" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 140
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intra_outbound_allow_all_ephemeral_rule" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 140
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "intra_inbound_allow_all_udp" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 141
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intra_outbound_allow_all_udp" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 141
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "intra_inbound_allow_all_udp_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 142 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intra_outbound_allow_all_udp_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 142 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
  egress         = true
}
###########################
# Database subnet ACL
###########################
resource "aws_network_acl_rule" "database_inbound_rdp_rule_deny" {
  network_acl_id = "${aws_network_acl.database.id}"
  cidr_block     = "0.0.0.0/0"
  rule_number    = 105
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "database" {
  network_acl_id = "${aws_network_acl.database.id}"
  rule_number    = 105
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "database_inbound_allow_443_rule" {
  network_acl_id = "${aws_network_acl.database.id}"
  rule_number    = 110
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "database_outbound_allow_443_rule" {
  network_acl_id = "${aws_network_acl.database.id}"
  rule_number    = 110
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "database_inbound_ssh_rule_deny" {
  network_acl_id = "${aws_network_acl.database.id}"
  cidr_block     = "0.0.0.0/0"
  rule_number    = 139
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "database_outbound_ssh_rule_deny" {
  network_acl_id = "${aws_network_acl.database.id}"
  rule_number    = 139
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "database_inbound_allow_all_ephemeral_rule" {
  network_acl_id = "${aws_network_acl.database.id}"
  rule_number    = 140
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "database_outbound_allow_all_ephemeral_rule" {
  network_acl_id = "${aws_network_acl.database.id}"
  rule_number    = 140
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  egress         = true
}
