# retrieves the availability zones from the specified region (see provider)
data "aws_availability_zones" "available" {}

locals {
  # elastic ip addresses - this should correspond with the number of
  # public subnets specified in `var.public_subnets`.
  eip_count = 3
  cidr_ip   = regex("[0-9]+.[0-9]+.[0-9]+.[0-9]+", length(var.secondary_cidr_blocks) > 0 ? var.secondary_cidr_blocks[0] : var.vpc_cidr)

  tags = var.cidr_name != "" ? { CIDR_NAME = var.cidr_name } : {}

  az_names = slice(data.aws_availability_zones.available.names, 0, var.number_of_azs)

  # vpc_tags = merge(var.vpc_tags, local.tags,var.eks_cluster_tags, { VPC = "${var.vpc_name}-${local.cidr_ip}" })
  vpc_tags = merge(var.vpc_tags)
}

# creates the elastic IPs which the NAT gateways are allocated
resource "aws_eip" "nat" {
  count = local.eip_count

  vpc  = true
  tags = merge(var.tags, local.tags, var.folder)
}

# virtual private cloud creator
module "vpc" {
  source = "github.com/GovTechSG/terraform-aws-vpc-forked?ref=v2.7.0-5"
  # source = ".//module"
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

  private_subnets = var.private_subnets

  private_subnet_tags = merge(
    var.eks_cluster_tags,
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
  enable_nat_gateway                 = true
  single_nat_gateway                 = false
  one_nat_gateway_per_az             = true
  reuse_nat_ips                      = true
  create_database_subnet_route_table = true
  external_nat_ip_ids                = aws_eip.nat.*.id

  # external services
  enable_s3_endpoint              = var.enable_s3_endpoint
  enable_dynamodb_endpoint        = var.enable_dynamodb_endpoint
  enable_ssm_endpoint             = var.enable_ssm_endpoint
  ssm_endpoint_security_group_ids = var.ssm_endpoint_security_group_ids
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
  count             = var.create_private_endpoints ? 1 : 0
  vpc_id            = module.vpc.vpc_id
  service_name      = data.aws_vpc_endpoint_service.ec2.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = [aws_security_group.allow_443.id]
  subnet_ids          = distinct(concat(data.aws_subnet.private_subnet_by_az.*.id, var.private_subnet_per_az_for_private_endpoints))
  private_dns_enabled = true
}

###########################
# VPC Endpoint for API Gateway
###########################
data "aws_vpc_endpoint_service" "api_gw" {
  service = "execute-api"
}

resource "aws_vpc_endpoint" "api_gw" {
  count             = var.create_api_gateway_private_endpoint ? 1 : 0
  vpc_id            = module.vpc.vpc_id
  service_name      = data.aws_vpc_endpoint_service.api_gw.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = [aws_security_group.allow_443.id]
  subnet_ids          = distinct(concat(data.aws_subnet.private_subnet_by_az.*.id, var.private_subnet_per_az_for_private_endpoints))
  private_dns_enabled = true
}

###########################
# VPC Endpoint for ECR API
###########################
data "aws_vpc_endpoint_service" "ecr_api" {
  service = "ecr.api"
}

resource "aws_vpc_endpoint" "ecr_api" {
  count             = var.create_private_endpoints ? 1 : 0
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
  count             = var.create_private_endpoints ? 1 : 0
  vpc_id            = module.vpc.vpc_id
  service_name      = data.aws_vpc_endpoint_service.ecr_dkr.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = [aws_security_group.allow_443.id]
  subnet_ids          = distinct(concat(data.aws_subnet.private_subnet_by_az.*.id, var.private_subnet_per_az_for_private_endpoints))
  private_dns_enabled = true
}

#######################
# VPC Endpoint for KMS
#######################
data "aws_vpc_endpoint_service" "kms" {
  service = "kms"
}

resource "aws_vpc_endpoint" "kms" {
  count = var.create_private_endpoints ? 1 : 0

  vpc_id            = module.vpc.vpc_id
  service_name      = data.aws_vpc_endpoint_service.kms.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = [aws_security_group.allow_443.id]
  subnet_ids          = distinct(concat(data.aws_subnet.private_subnet_by_az.*.id, var.private_subnet_per_az_for_private_endpoints))
  private_dns_enabled = true
}

#######################
# VPC Endpoint for STS
#######################
data "aws_vpc_endpoint_service" "sts" {
  service = "sts"
}

resource "aws_vpc_endpoint" "sts" {
  count = var.create_private_endpoints ? 1 : 0

  vpc_id            = module.vpc.vpc_id
  service_name      = data.aws_vpc_endpoint_service.sts.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = [aws_security_group.allow_443.id]
  subnet_ids          = distinct(concat(data.aws_subnet.private_subnet_by_az.*.id, var.private_subnet_per_az_for_private_endpoints))
  private_dns_enabled = true
}

#######################
# VPC Endpoint for SQS
#######################
data "aws_vpc_endpoint_service" "sqs" {
  service = "sqs"
}

resource "aws_vpc_endpoint" "sqs" {
  count = var.create_private_endpoints ? 1 : 0

  vpc_id            = module.vpc.vpc_id
  service_name      = data.aws_vpc_endpoint_service.sqs.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = [aws_security_group.allow_443.id]
  subnet_ids          = distinct(concat(data.aws_subnet.private_subnet_by_az.*.id, var.private_subnet_per_az_for_private_endpoints))
  private_dns_enabled = true
}

#######################
# VPC Endpoint for EFS
#######################
data "aws_vpc_endpoint_service" "efs" {
  service = "elasticfilesystem"
}

resource "aws_vpc_endpoint" "efs" {
  count = var.create_private_endpoints ? 1 : 0

  vpc_id            = module.vpc.vpc_id
  service_name      = data.aws_vpc_endpoint_service.efs.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = [aws_security_group.allow_443.id]
  subnet_ids          = distinct(concat(data.aws_subnet.private_subnet_by_az.*.id, var.private_subnet_per_az_for_private_endpoints))
  private_dns_enabled = true
}

#######################
# VPC Endpoint for Cloudwatch Logs
#######################
data "aws_vpc_endpoint_service" "cwl" {
  service = "logs"
}

resource "aws_vpc_endpoint" "cwl" {
  count = var.create_cwl_private_endpoint ? 1 : 0

  vpc_id            = module.vpc.vpc_id
  service_name      = data.aws_vpc_endpoint_service.cwl.service_name
  vpc_endpoint_type = "Interface"

  security_group_ids  = [aws_security_group.allow_443.id]
  subnet_ids          = distinct(concat(data.aws_subnet.private_subnet_by_az.*.id, var.private_subnet_per_az_for_private_endpoints))
  private_dns_enabled = true
}


#######################
# Security Groups
#######################

resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id
  tags   = merge(var.tags, local.tags, var.folder)

  dynamic "ingress" {
    for_each = var.default_security_group_rules
    content {
      from_port   = ingress.key
      to_port     = ingress.key
      cidr_blocks = ingress.value
      protocol    = "tcp"
    }
  }
}

resource "aws_security_group" "allow_443" {
  name        = "${var.vpc_name}-${local.cidr_ip}-allow-443"
  description = "Allow port 443 traffic to and from VPC cidr range"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.secondary_cidr_blocks
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.secondary_cidr_blocks
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
