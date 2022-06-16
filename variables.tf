variable "create_vpc" {
  description = "Controls if VPC should be created (it affects almost all resources)"
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
