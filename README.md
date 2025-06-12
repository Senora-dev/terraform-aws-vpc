# AWS VPC Terraform Module

This Terraform module creates a VPC with a customizable network topology in AWS.

## Features

- VPC with custom CIDR block
- Public, private, and database subnets across multiple Availability Zones
- Internet Gateway for public subnets
- NAT Gateway(s) with Elastic IPs for private subnets (configurable as single NAT or one per AZ)
- Route tables for all subnet types
- VPC Flow Logs support with CloudWatch or S3 destination
- Flexible tagging system for all resources

## Usage

### Basic VPC with Public and Private Subnets

```hcl
module "vpc" {
  source = "path/to/terraform-aws-vpc"

  name = "my-vpc"
  vpc_cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
```

### VPC with Public, Private, and Database Subnets

```hcl
module "vpc" {
  source = "path/to/terraform-aws-vpc"

  name = "complete-vpc"
  vpc_cidr = "10.0.0.0/16"

  azs              = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false # One NAT Gateway per AZ

  enable_flow_log = true
  flow_log_destination_type = "cloud-watch-logs"

  tags = {
    Environment = "prod"
    Terraform   = "true"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name to be used on all the resources as identifier | `string` | n/a | yes |
| vpc_cidr | The CIDR block for the VPC | `string` | n/a | yes |
| azs | A list of availability zones names or ids in the region | `list(string)` | n/a | yes |
| public_subnets | A list of public subnets inside the VPC | `list(string)` | `[]` | no |
| private_subnets | A list of private subnets inside the VPC | `list(string)` | `[]` | no |
| database_subnets | A list of database subnets inside the VPC | `list(string)` | `[]` | no |
| enable_nat_gateway | Should be true if you want to provision NAT Gateways | `bool` | `false` | no |
| single_nat_gateway | Should be true if you want to provision a single shared NAT Gateway across all private networks | `bool` | `false` | no |
| enable_flow_log | Whether or not to enable VPC Flow Logs | `bool` | `false` | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_arn | The ARN of the VPC |
| vpc_cidr_block | The CIDR block of the VPC |
| private_subnets | List of IDs of private subnets |
| public_subnets | List of IDs of public subnets |
| database_subnets | List of IDs of database subnets |
| nat_ids | List of allocation ID of Elastic IPs created for AWS NAT Gateway |
| natgw_ids | List of NAT Gateway IDs |
| igw_id | The ID of the Internet Gateway |

## Authors

Module is maintained by Your Organization

## License

Apache 2 Licensed. See LICENSE for full details.

## Maintainers

This module is maintained by [Senora.dev](https://senora.dev). 