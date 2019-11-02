#
# -----------------------------------------------------------------------------
# vpcs
# -----------------------------------------------------------------------------
#

output "vpc_azs" {
  description = "AZs at time of creation"
  value       = "${local.az_names}"
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = "${module.vpc.vpc_id}"
}

output "vpc_region" {
  description = "The region the VPC belongs to"
  value       = "${var.aws_region}"
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = "${module.vpc.vpc_cidr_block}"
}

#
# -----------------------------------------------------------------------------
# public subnets
# -----------------------------------------------------------------------------
#

output "public_subnets_ids" {
  description = "Public subnets for the VPC"
  value       = "${module.vpc.public_subnets}"
}

output "public_subnets_cidr_blocks" {
  description = "CIDR blocks for public subnets for the VPC"
  value       = "${module.vpc.public_subnets_cidr_blocks}"
}

output "vpc_public_route_table_ids" {
  description = "The IDs of the public route tables"
  value       = "${module.vpc.public_route_table_ids}"
}

#
# -----------------------------------------------------------------------------
# private subnets
# -----------------------------------------------------------------------------
#

output "private_subnets_ids" {
  description = "Private subnets for the VPC"
  value       = "${module.vpc.private_subnets}"
}

output "private_subnets_cidr_blocks" {
  description = "CIDR blocks fo private subnets for the VPC"
  value       = "${module.vpc.private_subnets_cidr_blocks}"
}

output "vpc_private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = "${module.vpc.private_route_table_ids}"
}

#
# -----------------------------------------------------------------------------
# database subnets
# -----------------------------------------------------------------------------
#

output "database_subnets_ids" {
  description = "Intranet subnets for the VPC"
  value       = "${module.vpc.database_subnets}"
}

output "database_subnets_cidr_blocks" {
  description = "CIDR blocks for database subnets for the VPC"
  value       = "${module.vpc.database_subnets_cidr_blocks}"
}

output "vpc_database_route_table_ids" {
  description = "List of IDs of database route tables"
  value       = "${module.vpc.database_route_table_ids}"
}

#
# -----------------------------------------------------------------------------
# intra subnets
# -----------------------------------------------------------------------------
#

output "intra_subnets_ids" {
  description = "Intranet subnets for the VPC"
  value       = "${module.vpc.intra_subnets}"
}

output "intra_subnets_cidr_blocks" {
  description = "CIDR blocks for intranet subnets for the VPC"
  value       = "${module.vpc.intra_subnets_cidr_blocks}"
}

output "vpc_intra_route_table_ids" {
  description = "List of IDs of intra route tables"
  value       = "${module.vpc.intra_route_table_ids}"
}

#
# -----------------------------------------------------------------------------
# gateways
# -----------------------------------------------------------------------------
#

output "vpc_nat_ids" {
  description = "NAT gateway IDs"
  value       = ["${module.vpc.natgw_ids}"]
}

output "vpc_nat_eip_ids" {
  description = "EIP for the NAT gateway in the VPC"
  value       = ["${module.vpc.nat_ids}"]
}

output "vpc_nat_eip_public" {
  description = "Public address for the EIP on the NAT Gateway"
  value       = ["${module.vpc.nat_public_ips}"]
}

output "vpc_igw_id" {
  description = "IGW ID"
  value       = "${module.vpc.igw_id}"
}

#
# -----------------------------------------------------------------------------
# route tables
# -----------------------------------------------------------------------------
#

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = "${module.vpc.vpc_main_route_table_id}"
}

#
# -----------------------------------------------------------------------------
# acls/security groups
# -----------------------------------------------------------------------------
#

output "default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = "${module.vpc.default_network_acl_id}"
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = "${module.vpc.default_security_group_id}"
}

output "public_network_acl_id" {
  description = "The ID of the public network ACL"
  value       = aws_network_acl.public.id
}

output "intranet_network_acl_id" {
  description = "The ID of the intra network ACL"
  value       = aws_network_acl.intra.id
}

output "private_network_acl_id" {
  description = "The ID of the privatenetwork ACL"
  value       = aws_network_acl.private.id
}

output "database_network_acl_id" {
  description = "The ID of the database network ACL"
  value       = aws_network_acl.database.id
}

#
# -----------------------------------------------------------------------------
# vpc_endpoints
# -----------------------------------------------------------------------------
#

output "ec2_endpoint" {
  description = "ID of ec2 endpoint"
  value       = "${aws_vpc_endpoint.ec2.id}"
}

output "ecr_endpoint" {
  description = "ID of ecr endpoint"
  value       = "${aws_vpc_endpoint.ecr_api.id}"
}

output "ecr_dkr_endpoint" {
  description = "ID of ecr_dkr endpoint"
  value       = "${aws_vpc_endpoint.ecr_dkr.id}"
}

output "s3_endpoint" {
  description = "ID of s3 endpoint"
  value       = "${module.vpc.vpc_endpoint_s3_id}"
}