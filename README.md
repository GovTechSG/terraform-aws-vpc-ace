# VPC

Opinionated module to create/provision a vpc, from [GovTechSG/terraform-aws-vpc-forked](https://github.com/GovTechSG/terraform-aws-vpc-forked)

As this module is intended to use with a EKS cluster, additional tags to be included in subnets are required, this is to prevent situations where this module is reapplied after EKS has been created, which will remove the tags that are automatically added by EKS.

Also, it is modified to work with GCC VPC resources, where there are multiple permission boundaries applied and our terraform permissions are restricted from modifying and creating certain objects.

## Gotchas with GCC

1. you cannot modify anything that has tag `Owner: GCCI`

Solution: Do not ever tag any of your resources with this value
You will notice that a number of resources in VPC dashboard that you cannot modify, not even adding additional tags. If you require additional tags, in the case of setting up EKS, where you need to tag the VPC [https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html) you will have to raise an SR to have someone from the technical desk to add it for you.

2. you cannot create NAT Gateways

This module will fail as it tries to create NAT Gateway for you, which GCC does not. Therefore you will have to either, raise a SR to create them, or raise a SR to request for a temporary lift of the permission boundaries for you to apply this module (Recommended)

## Usage

There are 2 ways to use this module, mainly

1. Create the vpc
2. Reuse a created VPC(that is empty) and provision it. This is in the case of GCC where VPC will be created for us, and we have no rights to create new vpcs. In this scenario, use the terraform `import` command to import the resource to the module for it to manage. e.g `terraform import 'module.vpc.aws_vpc.this[0]' vpc_xxxxxxx`

### Create vpc

```hcl
module "vpc" {
  vpc_cidr = "172.1.1.0/25"
  secondary_cidr_blocks = ["172.2.2.0/24"]
  manage_cidr_block = "172.2.2.0/24"
  vpc_tags = {
    "DataClassification" = "Official Close"
    "Type" = "Internet"
  }

  public_subnets_cidr_blocks = [
    "172.2.2.0/27",
  ]
  database_subnets_cidr_blocks = [
    "172.2.2.32/27,
  ]

  private_subnets_cidr_blocks = [
    "172.2.2.64/27",

  ]
  number_of_azs = 2

}
```

Note the usage of `secondary_cidr_blocks` and `manage_cidr_block`
As this module was originalyl intended to create 1 vpc with 1 cidr range for management, and it was only later discovered that GCC creates multiple cidr ranges in your VPC, you will have to use `manage_cidr_block` to tell the module to add create and manage resources for 1 cidr range at a time. Duplicate the module block for managing multiple cidrs as a workaround for now.

### Reuse VPC

#### Terraform

> terraform import 'module.vpc.aws_vpc.this[0]' vpc-xxxxxxxx
> terraform import 'module.vpc.aws_vpc_ipv4_cidr_block_association.this[0]' vpc-cidr-assoc-xxx
> terraform import 'module.vpc.aws_internet_gateway.this[0]' igw-xxx

#### Terragrunt

> terragrunt import 'module.vpc.aws_vpc.this[0]' vpc-xxxxxxxx
> terragrunt import 'module.vpc.aws_vpc_ipv4_cidr_block_association.this[0]' vpc-cidr-assoc-xxx
> terragrunt import 'module.vpc.aws_internet_gateway.this[0]' igw-xxx

## Upgrade

### from v1 to v2

In v2.0 onwards, this module will no longer try to compute subnet cidrs using `cidrsubnet` functions and rely on user input to enter the cidr ranges for each subnet by themselves, see usage for example

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | github.com/GovTechSG/terraform-aws-vpc-forked | v2.7.0-4 |

## Resources

| Name | Type |
|------|------|
| [aws_default_network_acl.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_network_acl) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_network_acl.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.intra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl_rule.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.database_inbound_allow_443_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.database_inbound_allow_all_ephemeral_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.database_inbound_rdp_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.database_inbound_ssh_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.database_outbound_allow_443_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.database_outbound_allow_all_ephemeral_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.database_outbound_ssh_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intra_inbound_allow_all_ephemeral_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intra_inbound_allow_all_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intra_inbound_allow_all_udp_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intra_inbound_allow_tcp_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intra_inbound_rdp_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intra_inbound_ssh_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intra_outbound_allow_all_ephemeral_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intra_outbound_allow_all_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intra_outbound_allow_all_udp_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intra_outbound_allow_tcp_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intra_outbound_rdp_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intra_outbound_ssh_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_inbound_allow_443_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_inbound_bgp_179_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_inbound_bgp_179_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_inbound_nfs_111_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_inbound_nfs_111_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_inbound_ssh_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_inbound_ssh_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_outbound_allow_443_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_outbound_bgp_179_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_outbound_bgp_179_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_outbound_nfs_111_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_outbound_nfs_111_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_outbound_ssh_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.intranet_outbound_ssh_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_allow_443_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_allow_80_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_allow_all_ephemeral_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_allow_all_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_allow_all_udp_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_allow_bgp_179_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_allow_bgp_179_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_allow_smtp_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_allow_tcp_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_ldap_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_ldap_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_nfs_111_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_nfs_111_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_openvpn_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_openvpn_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_rdp_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_ssh_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_ssh_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_inbound_ssh_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_allow_443_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_allow_80_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_allow_all_ephemeral_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_allow_all_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_allow_all_udp_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_allow_bgp_179_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_allow_bgp_179_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_allow_smtp_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_allow_tcp_dns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_ldap_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_ldap_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_nfs_111_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_nfs_111_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_openvpn_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_openvpn_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_rdp_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_ssh_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_ssh_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.private_outbound_ssh_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_inbound_allow_all_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_inbound_rdp_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_inbound_ssh_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_inbound_ssh_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_inbound_ssh_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_outbound_allow_all_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_outbound_rdp_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_outbound_ssh_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_outbound_ssh_rule_deny](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_network_acl_rule.public_outbound_ssh_rule_secondary_cidr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_security_group.allow_443](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.allow_http_https_outgoing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_vpc_endpoint.api_gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ecr_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.ecr_dkr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_network_acls.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/network_acls) | data source |
| [aws_subnet.private_subnet_by_az](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc_endpoint_service.api_gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |
| [aws_vpc_endpoint_service.ec2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |
| [aws_vpc_endpoint_service.ecr_api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |
| [aws_vpc_endpoint_service.ecr_dkr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |
| [aws_vpc_endpoint_service.efs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |
| [aws_vpc_endpoint_service.kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |
| [aws_vpc_endpoint_service.sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |
| [aws_vpc_endpoint_service.sts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc_endpoint_service) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Region to deploy current terraform script | `string` | `"ap-southeast-1"` | no |
| <a name="input_cidr_name"></a> [cidr\_name](#input\_cidr\_name) | Name of cidr managed | `string` | `""` | no |
| <a name="input_create_api_gateway_private_endpoint"></a> [create\_api\_gateway\_private\_endpoint](#input\_create\_api\_gateway\_private\_endpoint) | Whether to create private endpoint for API Gateway | `bool` | `false` | no |
| <a name="input_create_private_endpoints"></a> [create\_private\_endpoints](#input\_create\_private\_endpoints) | Whether to create private endpoints for s3,ec2 etc | `bool` | `true` | no |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | Controls if VPC should be created (it affects almost all resources) | `bool` | `true` | no |
| <a name="input_database_subnets_cidr_blocks"></a> [database\_subnets\_cidr\_blocks](#input\_database\_subnets\_cidr\_blocks) | cidr range of your database subnets | `list(string)` | `[]` | no |
| <a name="input_default_security_group_rules"></a> [default\_security\_group\_rules](#input\_default\_security\_group\_rules) | Allowed inbound rules for default security group | `map(any)` | `{}` | no |
| <a name="input_eks_cluster_tags"></a> [eks\_cluster\_tags](#input\_eks\_cluster\_tags) | List of tags that EKS will create, but also added to VPC for persistency across terraform applies | `map(any)` | n/a | yes |
| <a name="input_enable_dynamodb_endpoint"></a> [enable\_dynamodb\_endpoint](#input\_enable\_dynamodb\_endpoint) | Should be true if you want to provision a DynamoDB endpoint to the VPC | `bool` | `false` | no |
| <a name="input_enable_s3_endpoint"></a> [enable\_s3\_endpoint](#input\_enable\_s3\_endpoint) | Whether to create private s3 endpoint | `bool` | `true` | no |
| <a name="input_enable_ssm_endpoint"></a> [enable\_ssm\_endpoint](#input\_enable\_ssm\_endpoint) | Should be true if you want to provision an SSM endpoint to the VPC | `bool` | `false` | no |
| <a name="input_firewall_dedicated_network_acl"></a> [firewall\_dedicated\_network\_acl](#input\_firewall\_dedicated\_network\_acl) | Whether to use dedicated network ACL (not default) and custom rules for firewall subnets | `bool` | `false` | no |
| <a name="input_firewall_inbound_acl_rules"></a> [firewall\_inbound\_acl\_rules](#input\_firewall\_inbound\_acl\_rules) | firewall subnets inbound network ACL rules | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "allow",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_firewall_outbound_acl_rules"></a> [firewall\_outbound\_acl\_rules](#input\_firewall\_outbound\_acl\_rules) | Firewall subnets outbound network ACL rules | `list(map(string))` | <pre>[<br>  {<br>    "cidr_block": "0.0.0.0/0",<br>    "from_port": 0,<br>    "protocol": "-1",<br>    "rule_action": "allow",<br>    "rule_number": 100,<br>    "to_port": 0<br>  }<br>]</pre> | no |
| <a name="input_firewall_subnets_cidr_blocks"></a> [firewall\_subnets\_cidr\_blocks](#input\_firewall\_subnets\_cidr\_blocks) | cidr range of your firewall subnets | `list(string)` | `[]` | no |
| <a name="input_firewall_sync_states"></a> [firewall\_sync\_states](#input\_firewall\_sync\_states) | Output of aws\_networkfirewall\_firewall.firewall\_status[0].sync\_states | <pre>list(object({<br>    attachment = list(object({<br>      endpoint_id = string<br>      subnet_id   = string<br>    }))<br>    availability_zone = string<br>  }))</pre> | `[]` | no |
| <a name="input_folder"></a> [folder](#input\_folder) | Path relative to root of terraform directory where this module is used. This is for easier locating of where the individual resource is created with aws console | `map(any)` | n/a | yes |
| <a name="input_intranet_subnets_cidr_blocks"></a> [intranet\_subnets\_cidr\_blocks](#input\_intranet\_subnets\_cidr\_blocks) | cidr range of your intranet subnets | `list(string)` | `[]` | no |
| <a name="input_number_of_azs"></a> [number\_of\_azs](#input\_number\_of\_azs) | Determines number of availability zones to use in the region | `number` | `2` | no |
| <a name="input_private_subnet_per_az_for_private_endpoints"></a> [private\_subnet\_per\_az\_for\_private\_endpoints](#input\_private\_subnet\_per\_az\_for\_private\_endpoints) | list of private subnets that you want to join to a private endpoint | `list(any)` | `[]` | no |
| <a name="input_private_subnets_cidr_blocks"></a> [private\_subnets\_cidr\_blocks](#input\_private\_subnets\_cidr\_blocks) | cidr range of your private subnets | `list(string)` | `[]` | no |
| <a name="input_public_subnets_cidr_blocks"></a> [public\_subnets\_cidr\_blocks](#input\_public\_subnets\_cidr\_blocks) | cidr range of your public subnets | `list(string)` | `[]` | no |
| <a name="input_secondary_cidr_blocks"></a> [secondary\_cidr\_blocks](#input\_secondary\_cidr\_blocks) | List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool | `list(string)` | `[]` | no |
| <a name="input_ssm_endpoint_security_group_ids"></a> [ssm\_endpoint\_security\_group\_ids](#input\_ssm\_endpoint\_security\_group\_ids) | The ID of one or more security groups to associate with the network interface for SSM endpoint | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(any)` | `{}` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR for the VPC, check that this doesn't collide with an existing one | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC id for use in cases where VPC was already created and you would like to reuse it with this module. Not required if create\_vpc = true | `string` | `""` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name of VPC | `string` | n/a | yes |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | Tags to apply to VPC | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_database_network_acl_id"></a> [database\_network\_acl\_id](#output\_database\_network\_acl\_id) | The ID of the database network ACL |
| <a name="output_database_subnet_group"></a> [database\_subnet\_group](#output\_database\_subnet\_group) | Group name of the database subnet |
| <a name="output_database_subnets_cidr_blocks"></a> [database\_subnets\_cidr\_blocks](#output\_database\_subnets\_cidr\_blocks) | CIDR blocks for database subnets for the VPC |
| <a name="output_database_subnets_ids"></a> [database\_subnets\_ids](#output\_database\_subnets\_ids) | Intranet subnets for the VPC |
| <a name="output_default_network_acl_id"></a> [default\_network\_acl\_id](#output\_default\_network\_acl\_id) | The ID of the default network ACL |
| <a name="output_default_security_group_id"></a> [default\_security\_group\_id](#output\_default\_security\_group\_id) | The ID of the security group created by default on VPC creation |
| <a name="output_ec2_endpoint"></a> [ec2\_endpoint](#output\_ec2\_endpoint) | ID of ec2 endpoint |
| <a name="output_ecr_dkr_endpoint"></a> [ecr\_dkr\_endpoint](#output\_ecr\_dkr\_endpoint) | ID of ecr\_dkr endpoint |
| <a name="output_ecr_endpoint"></a> [ecr\_endpoint](#output\_ecr\_endpoint) | ID of ecr endpoint |
| <a name="output_firewall_network_acl_id"></a> [firewall\_network\_acl\_id](#output\_firewall\_network\_acl\_id) | The ID of the database network ACL |
| <a name="output_firewall_route_table_ids"></a> [firewall\_route\_table\_ids](#output\_firewall\_route\_table\_ids) | List of IDs of firewall route tables |
| <a name="output_firewall_subnet_arns"></a> [firewall\_subnet\_arns](#output\_firewall\_subnet\_arns) | List of ARNs of firewall subnets |
| <a name="output_firewall_subnets_cidr_blocks"></a> [firewall\_subnets\_cidr\_blocks](#output\_firewall\_subnets\_cidr\_blocks) | CIDR blocks for firewall subnets for the VPC |
| <a name="output_firewall_subnets_ids"></a> [firewall\_subnets\_ids](#output\_firewall\_subnets\_ids) | firewall subnets for the VPC |
| <a name="output_intra_subnets_cidr_blocks"></a> [intra\_subnets\_cidr\_blocks](#output\_intra\_subnets\_cidr\_blocks) | CIDR blocks for intranet subnets for the VPC |
| <a name="output_intra_subnets_ids"></a> [intra\_subnets\_ids](#output\_intra\_subnets\_ids) | Intranet subnets for the VPC |
| <a name="output_intranet_network_acl_id"></a> [intranet\_network\_acl\_id](#output\_intranet\_network\_acl\_id) | The ID of the intra network ACL |
| <a name="output_private_network_acl_id"></a> [private\_network\_acl\_id](#output\_private\_network\_acl\_id) | The ID of the privatenetwork ACL |
| <a name="output_private_subnet_per_az"></a> [private\_subnet\_per\_az](#output\_private\_subnet\_per\_az) | List of private subnets, 1 per AZ which are to be linked to private endpoints |
| <a name="output_private_subnets_cidr_blocks"></a> [private\_subnets\_cidr\_blocks](#output\_private\_subnets\_cidr\_blocks) | CIDR blocks fo private subnets for the VPC |
| <a name="output_private_subnets_ids"></a> [private\_subnets\_ids](#output\_private\_subnets\_ids) | Private subnets for the VPC |
| <a name="output_public_network_acl_id"></a> [public\_network\_acl\_id](#output\_public\_network\_acl\_id) | The ID of the public network ACL |
| <a name="output_public_subnets_cidr_blocks"></a> [public\_subnets\_cidr\_blocks](#output\_public\_subnets\_cidr\_blocks) | CIDR blocks for public subnets for the VPC |
| <a name="output_public_subnets_ids"></a> [public\_subnets\_ids](#output\_public\_subnets\_ids) | Public subnets for the VPC |
| <a name="output_s3_endpoint"></a> [s3\_endpoint](#output\_s3\_endpoint) | ID of s3 endpoint |
| <a name="output_vpc_azs"></a> [vpc\_azs](#output\_vpc\_azs) | AZs at time of creation |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_database_route_table_ids"></a> [vpc\_database\_route\_table\_ids](#output\_vpc\_database\_route\_table\_ids) | List of IDs of database route tables |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the created VPC |
| <a name="output_vpc_igw_id"></a> [vpc\_igw\_id](#output\_vpc\_igw\_id) | IGW ID |
| <a name="output_vpc_intra_route_table_ids"></a> [vpc\_intra\_route\_table\_ids](#output\_vpc\_intra\_route\_table\_ids) | List of IDs of intra route tables |
| <a name="output_vpc_main_route_table_id"></a> [vpc\_main\_route\_table\_id](#output\_vpc\_main\_route\_table\_id) | The ID of the main route table associated with this VPC |
| <a name="output_vpc_nat_eip_ids"></a> [vpc\_nat\_eip\_ids](#output\_vpc\_nat\_eip\_ids) | EIP for the NAT gateway in the VPC |
| <a name="output_vpc_nat_eip_public"></a> [vpc\_nat\_eip\_public](#output\_vpc\_nat\_eip\_public) | Public address for the EIP on the NAT Gateway |
| <a name="output_vpc_nat_ids"></a> [vpc\_nat\_ids](#output\_vpc\_nat\_ids) | NAT gateway IDs |
| <a name="output_vpc_private_route_table_ids"></a> [vpc\_private\_route\_table\_ids](#output\_vpc\_private\_route\_table\_ids) | List of IDs of private route tables |
| <a name="output_vpc_public_route_table_ids"></a> [vpc\_public\_route\_table\_ids](#output\_vpc\_public\_route\_table\_ids) | The IDs of the public route tables |
| <a name="output_vpc_region"></a> [vpc\_region](#output\_vpc\_region) | The region the VPC belongs to |
