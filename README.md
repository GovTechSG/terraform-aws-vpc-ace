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

  eks_cluster_tags = {
    "kubernetes.io/cluster/shire" = "shared"
  }
  number_of_azs = 2

  public_subnet_new_bits_size = "small"
  private_subnet_new_bits_size = "small"
  database_subnet_new_bits_size = "small"
  intranet_subnet_new_bits_size = "small"

  # number of subnets to create in each zone is defined by array size
  # You need to make sure you calculate your IP range out prior so as to ensure that you don't have overlapping
  # ip ranges. Use something like github/Terraform-FotD/cidrsubnet for deciding
  public_subnet_net_nums = [1, 2, 3]
  private_subnet_net_nums = [128,129,130]
  database_subnet_net_nums = [170, 171]
  intranet_subnet_net_nums = [253, 254, 255]
}
```

Note the usage of `secondary_cidr_blocks` and `manage_cidr_block`
As this module was originalyl intended to create 1 vpc with 1 cidr range for management, and it was only later discovered that GCC creates multiple cidr ranges in your VPC, you will have to use `manage_cidr_block` to tell the module to add create and manage resources for 1 cidr range at a time. Duplicate the module block for managing multiple cidrs as a workaround for now.

### Reuse VPC

#### Terraform

> terraform import 'module.vpc.aws_vpc.this[0]' vpc-xxxxxxxx

#### Terragrunt

> terragrunt import 'module.vpc.aws_vpc.this[0]' vpc-xxxxxxxx


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws\_region | Region to deploy current terraform script | string | `"ap-southeast-1"` | no |
| cidr\_name | Name of cidr managed | string | `""` | no |
| create\_vpc | Controls if VPC should be created (it affects almost all resources) | bool | `"true"` | no |
| database\_new\_bits | New bits of database subnet slice. See http://blog.itsjustcode.net/blog/2017/11/18/terraform-cidrsubnet-deconstructed/#what-is-newbits | map | `<map>` | no |
| database\_subnet\_net\_nums | list of netnums to use for database | list | n/a | yes |
| database\_subnet\_new\_bits\_size | Bit size to use | string | `"small"` | no |
| eks\_cluster\_tags | List of tags that EKS will create, but also added to VPC for persistency across terraform applies | map | n/a | yes |
| folder | Path relative to root of terraform directory where this module is used. This is for easier locating of where the individual resource is created with aws console | map | n/a | yes |
| intranet\_new\_bits | New bits of intranet subnet slice. See http://blog.itsjustcode.net/blog/2017/11/18/terraform-cidrsubnet-deconstructed/#what-is-newbits | map | `<map>` | no |
| intranet\_subnet\_net\_nums | list of netnums to use for intranet | list | n/a | yes |
| intranet\_subnet\_new\_bits\_size | Bit size to use | string | `"small"` | no |
| manage\_cidr\_block | CIDR Block that this resource is terraforming | string | `""` | no |
| number\_of\_azs | Determines number of availability zones to use in the region | number | `"2"` | no |
| private\_new\_bits | New bits of private subnet slice. See http://blog.itsjustcode.net/blog/2017/11/18/terraform-cidrsubnet-deconstructed/#what-is-newbits | map | `<map>` | no |
| private\_subnet\_net\_nums | list of netnums to use for private | list | n/a | yes |
| private\_subnet\_new\_bits\_size | Bit size to use | string | `"small"` | no |
| public\_new\_bits | New bits of public subnet slice. See http://blog.itsjustcode.net/blog/2017/11/18/terraform-cidrsubnet-deconstructed/#what-is-newbits | map | `<map>` | no |
| public\_subnet\_net\_nums | list of netnums to use for public | list | n/a | yes |
| public\_subnet\_new\_bits\_size | Bit size to use | string | `"small"` | no |
| secondary\_cidr\_blocks | List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool | list(string) | `<list>` | no |
| tags | Tags to apply to resources | map | `<map>` | no |
| vpc\_cidr | CIDR for the VPC, check that this doesn't collide with an existing one | string | n/a | yes |
| vpc\_id | VPC id for use in cases where VPC was already created and you would like to reuse it with this module. Not required if create_vpc = true | string | `""` | no |
| vpc\_name | Name of VPC | string | n/a | yes |
| vpc\_tags | Tags to apply to VPC | map | `<map>` | no |

## Outputs

| Name | Description |
|------|-------------|
| database\_network\_acl\_id | The ID of the database network ACL |
| database\_subnets\_cidr\_blocks | CIDR blocks for database subnets for the VPC |
| database\_subnets\_ids | Intranet subnets for the VPC |
| default\_network\_acl\_id | The ID of the default network ACL |
| default\_security\_group\_id | The ID of the security group created by default on VPC creation |
| ec2\_endpoint | ID of ec2 endpoint |
| ecr\_dkr\_endpoint | ID of ecr_dkr endpoint |
| ecr\_endpoint | ID of ecr endpoint |
| intra\_subnets\_cidr\_blocks | CIDR blocks for intranet subnets for the VPC |
| intra\_subnets\_ids | Intranet subnets for the VPC |
| intranet\_network\_acl\_id | The ID of the intra network ACL |
| private\_network\_acl\_id | The ID of the privatenetwork ACL |
| private\_subnets\_cidr\_blocks | CIDR blocks fo private subnets for the VPC |
| private\_subnets\_ids | Private subnets for the VPC |
| public\_network\_acl\_id | The ID of the public network ACL |
| public\_subnets\_cidr\_blocks | CIDR blocks for public subnets for the VPC |
| public\_subnets\_ids | Public subnets for the VPC |
| s3\_endpoint | ID of s3 endpoint |
| vpc\_azs | AZs at time of creation |
| vpc\_cidr\_block | The CIDR block of the VPC |
| vpc\_database\_route\_table\_ids | List of IDs of database route tables |
| vpc\_id | ID of the created VPC |
| vpc\_igw\_id | IGW ID |
| vpc\_intra\_route\_table\_ids | List of IDs of intra route tables |
| vpc\_main\_route\_table\_id | The ID of the main route table associated with this VPC |
| vpc\_nat\_eip\_ids | EIP for the NAT gateway in the VPC |
| vpc\_nat\_eip\_public | Public address for the EIP on the NAT Gateway |
| vpc\_nat\_ids | NAT gateway IDs |
| vpc\_private\_route\_table\_ids | List of IDs of private route tables |
| vpc\_public\_route\_table\_ids | The IDs of the public route tables |
| vpc\_region | The region the VPC belongs to |
