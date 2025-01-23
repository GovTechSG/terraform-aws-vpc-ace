locals {
  create_private  = length(var.private_subnets) > 0
  create_public   = length(var.public_subnets) > 0
  create_intranet = length(var.intranet_subnets) > 0
  create_database = length(var.database_subnets) > 0
}

# override default network acl

resource "aws_default_network_acl" "default" {
  count                  = var.manage_default_network_acl ? 1 : 0
  default_network_acl_id = tolist(data.aws_network_acls.default.ids)[0]

  tags = merge({ "Name" = "${var.vpc_name}-default" }, var.tags, local.tags, var.folder)
  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

data "aws_network_acls" "default" {
  vpc_id = module.vpc.vpc_id

  filter {
    name   = "default"
    values = ["true"]
  }
}

resource "aws_network_acl" "private" {
  count      = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  tags       = merge({ "Name" = "${var.vpc_name}-private" }, var.tags, local.tags, var.folder)
}

resource "aws_network_acl" "public" {
  count      = local.create_public && !var.public_dedicated_network_acl ? 1 : 0
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets
  tags       = merge({ "Name" = "${var.vpc_name}-public" }, var.tags, local.tags, var.folder)
}

resource "aws_network_acl" "intra" {
  count      = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.intra_subnets
  tags       = merge({ "Name" = "${var.vpc_name}-intra" }, var.tags, local.tags, var.folder)
}

resource "aws_network_acl" "database" {
  count      = local.create_database && !var.database_dedicated_network_acl ? 1 : 0
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnets
  tags       = merge({ "Name" = "${var.vpc_name}-database" }, var.tags, local.tags, var.folder)
}


###########################
# Public subnet ACL
###########################

resource "aws_network_acl_rule" "public_inbound_rdp_rule_deny" {
  count          = local.create_public && !var.public_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.public[0].id
  cidr_block     = "0.0.0.0/0"
  rule_number    = 110
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "public_outbound_rdp_rule_deny" {
  count          = local.create_public && !var.public_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 110
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "public_inbound_rdp_rule_deny_udp" {
  count          = local.create_public && !var.public_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.public[0].id
  cidr_block     = "0.0.0.0/0"
  rule_number    = 120
  protocol       = "udp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "public_outbound_rdp_rule_deny_udp" {
  count          = local.create_public && !var.public_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 120
  cidr_block     = "0.0.0.0/0"
  protocol       = "udp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "public_inbound_ssh_rule" {
  count          = local.create_public && !var.public_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 130
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "public_outbound_ssh_rule" {
  count          = local.create_public && !var.public_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 130
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "public_inbound_ssh_rule_secondary_cidr" {
  count          = local.create_public && !var.public_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 140 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "public_outbound_ssh_rule_secondary_cidr" {
  count          = local.create_public && !var.public_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 140 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "public_inbound_ssh_rule_deny" {
  count          = local.create_public && !var.public_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.public[0].id
  cidr_block     = "0.0.0.0/0"
  rule_number    = 150
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "public_outbound_ssh_rule_deny" {
  count          = local.create_public && !var.public_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 150
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "public_inbound_allow_all_rule" {
  count          = local.create_public && !var.public_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 160
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "public_outbound_allow_all_rule" {
  count          = local.create_public && !var.public_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.public[0].id
  rule_number    = 160
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
  egress         = true
}

###########################
# Private subnet ACL
###########################
resource "aws_network_acl_rule" "private_inbound_rdp_rule_deny" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  cidr_block     = "0.0.0.0/0"
  rule_number    = 110
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "private_outbound_rdp_rule_deny" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 110
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_rdp_rule_deny_udp" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  cidr_block     = "0.0.0.0/0"
  rule_number    = 120
  protocol       = "udp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "private_outbound_rdp_rule_deny_udp" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 120
  cidr_block     = "0.0.0.0/0"
  protocol       = "udp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_allow_80_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 200
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 80
  to_port        = 80
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_80_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 200
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 80
  to_port        = 80
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_allow_443_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 210
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_443_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 210
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_nfs_111_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 220
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_nfs_111_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 220
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_nfs_111_rule_secondary_cidr" {
  count          = local.create_private && !var.private_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 230 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_nfs_111_rule_secondary_cidr" {
  count          = local.create_private && !var.private_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 230 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_ssh_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 240
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_ssh_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 240
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_ssh_rule_secondary_cidr" {
  count          = local.create_private && !var.private_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 250 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_ssh_rule_secondary_cidr" {
  count          = local.create_private && !var.private_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 250 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_ldap_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 260
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 389
  to_port        = 389
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_ldap_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 260
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 389
  to_port        = 389
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_ldap_rule_secondary_cidr" {
  count          = local.create_private && !var.private_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 270 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 389
  to_port        = 389
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_ldap_rule_secondary_cidr" {
  count          = local.create_private && !var.private_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 270 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 389
  to_port        = 389
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_openvpn_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 280
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 943
  to_port        = 943
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_openvpn_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 280
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 943
  to_port        = 943
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_openvpn_rule_secondary_cidr" {
  count          = local.create_private && !var.private_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 290 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 943
  to_port        = 943
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_openvpn_rule_secondary_cidr" {
  count          = local.create_private && !var.private_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 290 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 943
  to_port        = 943
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_ssh_rule_deny" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  cidr_block     = "0.0.0.0/0"
  rule_number    = 300
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "private_outbound_ssh_rule_deny" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 300
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_allow_smtp_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 900
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 587
  to_port        = 587
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_smtp_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 900
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 587
  to_port        = 587
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_allow_bgp_179_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 910
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_bgp_179_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 910
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_allow_bgp_179_secondary_cidr" {
  count          = local.create_private && !var.private_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 920 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_bgp_179_secondary_cidr" {
  count          = local.create_private && !var.private_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 920 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "private_inbound_allow_all_ephemeral_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 1100
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_all_ephemeral_rule" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 1100
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_outbound_allow_all_ephemeral_rule_secondary_cidr" {
  count          = local.create_private && !var.private_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 1110 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_allow_all_udp" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 1000
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_all_udp" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 1000
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_allow_all_udp_secondary_cidr" {
  count          = local.create_private && !var.private_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 1101 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_all_udp_secondary_cidr" {
  count          = local.create_private && !var.private_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 1101 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_allow_tcp_dns" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 1200
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 53
  to_port        = 53
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_tcp_dns" {
  count          = local.create_private && !var.private_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.private[0].id
  rule_number    = 1200
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 53
  to_port        = 53
  rule_action    = "allow"
  egress         = "true"
}

###########################
# Intranet subnet ACL
###########################

resource "aws_network_acl_rule" "intra_inbound_rdp_rule_deny" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  cidr_block     = "0.0.0.0/0"
  rule_number    = 110
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "intra_outbound_rdp_rule_deny" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 110
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "intranet_inbound_allow_443_rule" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 200
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_allow_443_rule" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 200
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "intranet_inbound_nfs_111_rule" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 210
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_nfs_111_rule" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 210
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "intranet_inbound_nfs_111_rule_secondary_cidr" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 220 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_nfs_111_rule_secondary_cidr" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 220 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "intranet_inbound_ssh_rule" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 230
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_ssh_rule" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 230
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "intranet_inbound_ssh_rule_secondary_cidr" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 240 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_ssh_rule_secondary_cidr" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 240 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "intra_inbound_ssh_rule_deny" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 250
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "intra_outbound_ssh_rule_deny" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 250
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "intranet_inbound_bgp_179_rule" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 910
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_bgp_179_rule" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 910
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "intranet_inbound_bgp_179_rule_secondary_cidr" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 920 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_bgp_179_rule_secondary_cidr" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 920 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "intra_inbound_allow_all_udp" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 1000
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intra_outbound_allow_all_udp" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 1000
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "intra_inbound_allow_all_udp_secondary_cidr" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 1010 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intra_outbound_allow_all_udp_secondary_cidr" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 1010 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "udp"
  from_port      = 1
  to_port        = 65535
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "intra_inbound_allow_all_ephemeral_rule" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 1100
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intra_outbound_allow_all_ephemeral_rule" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 1100
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "intra_outbound_allow_all_ephemeral_rule_secondary_cidr" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 1110 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  egress         = "true"
}

# To allow traffic between VPCs connected to a transit gateway, you need to open the necessary ports in the
# security groups attached to the network interfaces in those VPCs.
# The key ports required for transit gateway connectivity are:
# - Port 443 for HTTPS communication between the VPCs and transit gateway control plane.
# - Port 2049 for NFS traffic if you enable file sharing using NFS.
# - Ports from 1024 to 65535 for
# ALB: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-troubleshooting.html
# The network ACL associated with the subnets for your load balancer nodes must allow inbound traffic on the ephemeral ports and outbound traffic on the health check and ephemeral ports.
# Generic Routing Encapsulation (GRE) tunnels if you use appliance mode.
#     Appliance mode allows you to deploy virtual appliances for functions like routing,
#     firewalling etc across connected VPCs.
resource "aws_network_acl_rule" "intra_outbound_allow_all_ephemeral_rule_tgw" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 1150
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "intra_inbound_allow_tcp_dns" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 1200
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 53
  to_port        = 53
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intra_outbound_allow_tcp_dns" {
  count          = local.create_intranet && !var.intra_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.intra[0].id
  rule_number    = 1200
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 53
  to_port        = 53
  rule_action    = "allow"
  egress         = "true"
}

###########################
# Database subnet ACL
###########################
resource "aws_network_acl_rule" "database_inbound_rdp_rule_deny" {
  count          = local.create_database && !var.database_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.database[0].id
  cidr_block     = "0.0.0.0/0"
  rule_number    = 110
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "database_outbound_rdp_rule_deny" {
  count          = local.create_database && !var.database_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.database[0].id
  rule_number    = 110
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 3389
  to_port        = 3389
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "database_inbound_ssh_rule_deny" {
  count          = local.create_database && !var.database_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.database[0].id
  cidr_block     = "0.0.0.0/0"
  rule_number    = 120
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
}

resource "aws_network_acl_rule" "database_outbound_ssh_rule_deny" {
  count          = local.create_database && !var.database_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.database[0].id
  rule_number    = 120
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 22
  to_port        = 22
  rule_action    = "deny"
  egress         = true
}

resource "aws_network_acl_rule" "database_inbound_allow_443_rule" {
  count          = local.create_database && !var.database_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.database[0].id
  rule_number    = 200
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "database_outbound_allow_443_rule" {
  count          = local.create_database && !var.database_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.database[0].id
  rule_number    = 200
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "database_inbound_allow_all_ephemeral_rule" {
  count          = local.create_database && !var.database_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.database[0].id
  rule_number    = 1000
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "database_outbound_allow_all_ephemeral_rule" {
  count          = local.create_database && !var.database_dedicated_network_acl ? 1 : 0
  network_acl_id = aws_network_acl.database[0].id
  rule_number    = 1000
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "database_inbound_allow_all_ephemeral_rule_secondary_cidr" {
  count          = local.create_database && !var.database_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.database[0].id
  rule_number    = 1010 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "database_outbound_allow_all_ephemeral_rule_secondary_cidr" {
  count          = local.create_database && !var.database_dedicated_network_acl ? length(var.secondary_cidr_blocks) : 0
  network_acl_id = aws_network_acl.database[0].id
  rule_number    = 1010 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  egress         = true
}
