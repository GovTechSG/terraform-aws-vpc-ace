
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

###########################
# Private subnet ACL
###########################
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
  protocol       = "tcp"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_nfs_111_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 115
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
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
  protocol       = "tcp"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_nfs_111_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 116 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
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
  from_port      = 700
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_all_ephemeral_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 140
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 700
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

resource "aws_network_acl_rule" "private_inbound_allow_tcp_dns" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 147
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 53
  to_port        = 53
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_tcp_dns" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 147
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 53
  to_port        = 53
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_allow_smtp_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 150
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 587
  to_port        = 587
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_smtp_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 150
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 587
  to_port        = 587
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_allow_bgp_179_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 153
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_bgp_179_rule" {
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 153
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
  egress         = "true"
}

resource "aws_network_acl_rule" "private_inbound_allow_bgp_179_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 154 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "private_outbound_allow_bgp_179_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.private.id}"
  rule_number    = 154 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
  egress         = true
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

resource "aws_network_acl_rule" "intranet_inbound_nfs_111_rule" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 115
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_nfs_111_rule" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 115
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
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
  protocol       = "tcp"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_nfs_111_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 116 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 111
  to_port        = 111
  rule_action    = "allow"
  egress         = true
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
  from_port      = 700
  to_port        = 65535
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intra_outbound_allow_all_ephemeral_rule" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 140
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 700
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

resource "aws_network_acl_rule" "intra_inbound_allow_tcp_dns" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 147
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 53
  to_port        = 53
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intra_outbound_allow_tcp_dns" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 147
  cidr_block     = "0.0.0.0/0"
  protocol       = "tcp"
  from_port      = 53
  to_port        = 53
  rule_action    = "allow"
  egress         = "true"
}


resource "aws_network_acl_rule" "intranet_inbound_bgp_179_rule" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 153
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_bgp_179_rule" {
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 153
  cidr_block     = module.vpc.vpc_cidr_block
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
  egress         = true
}

resource "aws_network_acl_rule" "intranet_inbound_bgp_179_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 154 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
  rule_action    = "allow"
}

resource "aws_network_acl_rule" "intranet_outbound_bgp_179_rule_secondary_cidr" {
  count          = length(var.secondary_cidr_blocks)
  network_acl_id = "${aws_network_acl.intra.id}"
  rule_number    = 154 + count.index
  cidr_block     = var.secondary_cidr_blocks[count.index]
  protocol       = "tcp"
  from_port      = 179
  to_port        = 179
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
