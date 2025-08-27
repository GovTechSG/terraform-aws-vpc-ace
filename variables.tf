variable "create_vpc" {
  description = "Controls if VPC should be created (it affects almost all resources)"
  type        = bool
  default     = true
}

variable "create_allow_443_security_group" {
  description = "Controls if the allow_443 security group should be created"
  type        = bool
  default     = true
}

variable "create_allow_http_https_outgoing_security_group" {
  description = "Controls if the allow_http_https_outgoing security group should be created"
  type        = bool
  default     = true
}

variable "vpc_name" {
  description = "Name of VPC"
  type        = string
}

variable "cidr_name" {
  description = "Name of cidr managed"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC id for use in cases where VPC was already created and you would like to reuse it with this module. Not required if create_vpc = true"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "Region to deploy current terraform script"
  type        = string
  default     = "ap-southeast-1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(any)
  default     = {}
}

variable "vpc_tags" {
  description = "Tags to apply to VPC"
  type        = map(any)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR for the VPC, check that this doesn't collide with an existing one"
  type        = string
}

variable "folder" {
  description = "Path relative to root of terraform directory where this module is used. This is for easier locating of where the individual resource is created with aws console"
  type        = map(any)
}

variable "eks_cluster_tags" {
  description = "List of tags that EKS will create, but also added to VPC for persistency across terraform applies"
  type        = map(any)
  default     = {}
}

variable "eks_public_subnet_tags" {
  description = "Additional EKS-specific tags to apply to public subnets only"
  type        = map(any)
  default     = {}
}

variable "eks_private_subnet_tags" {
  description = "Additional EKS-specific tags to apply to private subnets only"
  type        = map(any)
  default     = {}
}

variable "eks_intra_subnet_tags" {
  description = "Additional EKS-specific tags to apply to intra subnets only"
  type        = map(any)
  default     = {}
}

variable "number_of_azs" {
  description = "Determines number of availability zones to use in the region"
  default     = 2
  type        = number
}

variable "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool"
  type        = list(string)
  default     = []
}

variable "default_security_group_rules" {
  description = "Allowed inbound rules for default security group"
  type        = map(any)
  default     = {}
  // Example input map
  // {
  //   "22"  = ["192.168.1.0/24", "10.1.1.0/24" ]
  //   "443" = ["0.0.0.0/0"]
  // }
}

variable "intranet_subnets" {
  description = "cidr range of your intranet subnets"
  type        = list(string)
  default     = []
}

variable "public_subnets" {
  description = "cidr range of your public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnets" {
  description = "cidr range of your private subnets"
  type        = list(string)
  default     = []
}

variable "database_subnets" {
  description = "cidr range of your database subnets"
  type        = list(string)
  default     = []
}

variable "firewall_subnets" {
  description = "cidr range of your firewall subnets"
  type        = list(string)
  default     = []
}

variable "firewall_sync_states" {
  description = "Output of aws_networkfirewall_firewall.firewall_status[0].sync_states"
  type = list(object({
    attachment = list(object({
      endpoint_id = string
      subnet_id   = string
    }))
    availability_zone = string
  }))
  default = []
}

variable "firewall_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL (not default) and custom rules for firewall subnets"
  type        = bool
  default     = false
}

variable "firewall_inbound_acl_rules" {
  description = "firewall subnets inbound network ACL rules"
  type        = list(map(string))

  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = true
}

variable "firewall_outbound_acl_rules" {
  description = "Firewall subnets outbound network ACL rules"
  type        = list(map(string))

  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "map_public_ip_on_launch" {
  description = "Should be false if you do not want to auto-assign public IP on launch"
  type        = bool
  default     = true
}

variable "manage_default_network_acl" {
  description = "Should be true to adopt and manage Default Network ACL"
  type        = bool
  default     = false
}

variable "default_network_acl_name" {
  description = "Name to be used on the Default Network ACL"
  type        = string
  default     = ""
}

variable "default_network_acl_tags" {
  description = "Additional tags for the Default Network ACL"
  type        = map(string)
  default     = {}
}

################################################################################
# Flow Log
################################################################################

variable "enable_flow_log" {
  description = "Whether or not to enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "vpc_flow_log_permissions_boundary" {
  description = "The ARN of the Permissions Boundary for the VPC Flow Log IAM Role"
  type        = string
  default     = null
}

variable "flow_log_max_aggregation_interval" {
  description = "The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: `60` seconds or `600` seconds"
  type        = number
  default     = 600
}

variable "flow_log_traffic_type" {
  description = "The type of traffic to capture. Valid values: ACCEPT, REJECT, ALL"
  type        = string
  default     = "ALL"
}

variable "flow_log_destination_type" {
  description = "Type of flow log destination. Can be s3 or cloud-watch-logs"
  type        = string
  default     = "cloud-watch-logs"
}

variable "flow_log_log_format" {
  description = "The fields to include in the flow log record, in the order in which they should appear"
  type        = string
  default     = null
}

variable "flow_log_destination_arn" {
  description = "The ARN of the CloudWatch log group or S3 bucket where VPC Flow Logs will be pushed. If this ARN is a S3 bucket the appropriate permissions need to be set on that bucket's policy. When create_flow_log_cloudwatch_log_group is set to false this argument must be provided"
  type        = string
  default     = ""
}

variable "flow_log_file_format" {
  description = "(Optional) The format for the flow log. Valid values: `plain-text`, `parquet`"
  type        = string
  default     = null
}

variable "flow_log_hive_compatible_partitions" {
  description = "(Optional) Indicates whether to use Hive-compatible prefixes for flow logs stored in Amazon S3"
  type        = bool
  default     = false
}

variable "flow_log_per_hour_partition" {
  description = "(Optional) Indicates whether to partition the flow log per hour. This reduces the cost and response time for queries"
  type        = bool
  default     = false
}

variable "vpc_flow_log_tags" {
  description = "Additional tags for the VPC Flow Logs"
  type        = map(string)
  default     = {}
}

variable "lg_filters" {
  description = "Log group filters for Network Firewall"
  type = map(object({
    naming_suffix   = string
    role_arn        = string
    filter_pattern  = string
    destination_arn = string
    distribution    = string
  }))
  default = {}
}

################################################################################
# Flow Log CloudWatch
################################################################################

variable "create_flow_log_cloudwatch_log_group" {
  description = "Whether to create CloudWatch log group for VPC Flow Logs"
  type        = bool
  default     = false
}

variable "create_flow_log_cloudwatch_iam_role" {
  description = "Whether to create IAM role for VPC Flow Logs"
  type        = bool
  default     = false
}

variable "flow_log_cloudwatch_iam_role_arn" {
  description = "The ARN for the IAM role that's used to post flow logs to a CloudWatch Logs log group. When flow_log_destination_arn is set to ARN of Cloudwatch Logs, this argument needs to be provided"
  type        = string
  default     = ""
}

variable "flow_log_cloudwatch_log_group_name_prefix" {
  description = "Specifies the name prefix of CloudWatch Log Group for VPC flow logs"
  type        = string
  default     = "/aws/vpc-flow-log/"
}

variable "flow_log_cloudwatch_log_group_name_suffix" {
  description = "Specifies the name suffix of CloudWatch Log Group for VPC flow logs"
  type        = string
  default     = ""
}

variable "flow_log_cloudwatch_log_group_retention_in_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group for VPC flow logs"
  type        = number
  default     = null
}

variable "flow_log_cloudwatch_log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data for VPC flow logs"
  type        = string
  default     = null
}


################################################################################
# Default VPC
################################################################################

variable "manage_default_vpc" {
  description = "Should be true to adopt and manage Default VPC"
  type        = bool
  default     = false
}

variable "default_vpc_name" {
  description = "Name to be used on the Default VPC"
  type        = string
  default     = null
}

variable "default_vpc_enable_dns_support" {
  description = "Should be true to enable DNS support in the Default VPC"
  type        = bool
  default     = true
}

variable "default_vpc_enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the Default VPC"
  type        = bool
  default     = true
}

variable "default_vpc_tags" {
  description = "Additional tags for the Default VPC"
  type        = map(string)
  default     = {}
}

variable "manage_default_security_group" {
  description = "Should be true to adopt and manage default security group"
  type        = bool
  default     = true
}

variable "default_security_group_name" {
  description = "Name to be used on the default security group"
  type        = string
  default     = null
}

variable "default_security_group_ingress" {
  description = "List of maps of ingress rules to set on the default security group"
  type        = list(map(string))
  default     = []
}

variable "default_security_group_egress" {
  description = "List of maps of egress rules to set on the default security group"
  type        = list(map(string))
  default     = []
}

variable "default_security_group_tags" {
  description = "Additional tags for the default security group"
  type        = map(string)
  default     = {}
}


################################################################################
# Default Route
################################################################################

variable "manage_default_route_table" {
  description = "Should be true to manage default route table"
  type        = bool
  default     = true
}

variable "default_route_table_name" {
  description = "Name to be used on the default route table"
  type        = string
  default     = null
}

variable "default_route_table_propagating_vgws" {
  description = "List of virtual gateways for propagation"
  type        = list(string)
  default     = []
}

variable "default_route_table_routes" {
  description = "Configuration block of routes. See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table#route"
  type        = list(map(string))
  default     = []
}

variable "default_route_table_tags" {
  description = "Additional tags for the default route table"
  type        = map(string)
  default     = {}
}

################################################################################
# Public Network ACLs
################################################################################

variable "public_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL (not default) and custom rules for public subnets"
  type        = bool
  default     = false
}

variable "public_inbound_acl_rules" {
  description = "Public subnets inbound network ACLs"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "public_outbound_acl_rules" {
  description = "Public subnets outbound network ACLs"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "public_acl_tags" {
  description = "Additional tags for the public subnets network ACL"
  type        = map(string)
  default     = {}
}

################################################################################
# Private Network ACLs
################################################################################

variable "private_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL (not default) and custom rules for private subnets"
  type        = bool
  default     = false
}

variable "private_inbound_acl_rules" {
  description = "Private subnets inbound network ACLs"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "private_outbound_acl_rules" {
  description = "Private subnets outbound network ACLs"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "private_acl_tags" {
  description = "Additional tags for the private subnets network ACL"
  type        = map(string)
  default     = {}
}

################################################################################
# Database Network ACLs
################################################################################

variable "database_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL (not default) and custom rules for database subnets"
  type        = bool
  default     = false
}

variable "database_inbound_acl_rules" {
  description = "Database subnets inbound network ACL rules"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "database_outbound_acl_rules" {
  description = "Database subnets outbound network ACL rules"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "database_acl_tags" {
  description = "Additional tags for the database subnets network ACL"
  type        = map(string)
  default     = {}
}

################################################################################
# Intra Network ACLs
################################################################################

variable "intra_dedicated_network_acl" {
  description = "Whether to use dedicated network ACL (not default) and custom rules for intra subnets"
  type        = bool
  default     = false
}

variable "intra_inbound_acl_rules" {
  description = "Intra subnets inbound network ACLs"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "intra_outbound_acl_rules" {
  description = "Intra subnets outbound network ACLs"
  type        = list(map(string))
  default = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"
    },
  ]
}

variable "intra_acl_tags" {
  description = "Additional tags for the intra subnets network ACL"
  type        = map(string)
  default     = {}
}

################################################################################
# Default Network ACLs
################################################################################
variable "default_network_acl_ingress" {
  description = "List of maps of ingress rules to set on the Default Network ACL"
  type        = list(map(string))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_no         = 101
      action          = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
}

variable "default_network_acl_egress" {
  description = "List of maps of egress rules to set on the Default Network ACL"
  type        = list(map(string))
  default = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    },
    {
      rule_no         = 101
      action          = "allow"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      ipv6_cidr_block = "::/0"
    },
  ]
}
