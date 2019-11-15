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

variable "public_subnet_net_nums" {
  description = "list of netnums to use for public"
  type        = list
}

variable "public_new_bits" {
  description = "New bits of public subnet slice. See http://blog.itsjustcode.net/blog/2017/11/18/terraform-cidrsubnet-deconstructed/#what-is-newbits"
  type        = map
  default = {
    xsmall  = "9"
    small   = "8"
    xmedium  = "7"
    medium  = "6"
    large   = "5"
    xlarge  = "4"
    xxlarge = "3"
    xxxlarge = "2"
  }
}

variable "public_subnet_new_bits_size" {
  description = "Bit size to use"
  type        = string
  default     = "small"
}

variable "private_subnet_net_nums" {
  description = "list of netnums to use for private"
  type        = list
}

variable "secondary_private_subnet_net_nums" {
  description = "list of netnums to use for private"
  type        = list
  default     = []
}

variable "private_new_bits" {
  description = "New bits of private subnet slice. See http://blog.itsjustcode.net/blog/2017/11/18/terraform-cidrsubnet-deconstructed/#what-is-newbits"
  type        = map
  default = {
    xsmall  = "9"
    small   = "8"
    xmedium  = "7"
    medium  = "6"
    large   = "5"
    xlarge  = "4"
    xxlarge = "3"
    xxxlarge = "2"
  }
}

variable "private_subnet_new_bits_size" {
  description = "Bit size to use"
  type        = string
  default     = "small"
}

variable "secondary_private_subnet_new_bits_size" {
  description = "Bit size to use"
  type        = string
  default     = "small"
}

variable "intranet_subnet_net_nums" {
  description = "list of netnums to use for intranet"
  type        = list
}

variable "intranet_new_bits" {
  description = "New bits of intranet subnet slice. See http://blog.itsjustcode.net/blog/2017/11/18/terraform-cidrsubnet-deconstructed/#what-is-newbits"
  type        = map
  default = {
    xsmall  = "9"
    small   = "8"
    xmedium  = "7"
    medium  = "6"
    large   = "5"
    xlarge  = "4"
    xxlarge = "3"
    xxxlarge = "2"
  }
}

variable "intranet_subnet_new_bits_size" {
  description = "Bit size to use"
  type        = string
  default     = "small"
}

variable "database_subnet_net_nums" {
  description = "list of netnums to use for database"
  type        = list
}

variable "database_new_bits" {
  description = "New bits of database subnet slice. See http://blog.itsjustcode.net/blog/2017/11/18/terraform-cidrsubnet-deconstructed/#what-is-newbits"
  type        = map
  default = {
    xsmall  = "9"
    small   = "8"
    xmedium  = "7"
    medium  = "6"
    large   = "5"
    xlarge  = "4"
    xxlarge = "3"
    xxxlarge = "2"
  }
}

variable "database_subnet_new_bits_size" {
  description = "Bit size to use"
  type        = string
  default     = "small"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map
  default     = {}
}

variable "vpc_tags" {
  description = "Tags to apply to VPC"
  type        = map
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR for the VPC, check that this doesn't collide with an existing one"
  type        = string
}

variable "vpc_peering_connection_id" {
  description = "ID of the GDSHIVE VPC Peering Connection if we are the acceptor"
  type        = string
  default     = ""
}

variable "folder" {
  description = "Path relative to root of terraform directory where this module is used. This is for easier locating of where the individual resource is created with aws console"
  type        = map
}

variable "eks_cluster_tags" {
  description = "List of tags that EKS will create, but also added to VPC for persistency across terraform applies"
  type        = map
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

variable "manage_cidr_block" {
  description = "CIDR Block that this resource is terraforming"
  type        = string
  default     = ""
}

