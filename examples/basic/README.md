# Basic VPC Example

This example demonstrates how to use the VPC module in its simplest form.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources anymore.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0 |

## Resources Created

- VPC with CIDR block 10.0.0.0/16
- 3 public subnets in different availability zones
- 3 private subnets in different availability zones
- Internet Gateway
- Single NAT Gateway (for cost optimization)
- Route tables for public and private subnets
- Network ACLs

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| public_subnets | List of IDs of public subnets |
| private_subnets | List of IDs of private subnets |
| nat_gateway_ids | List of NAT Gateway IDs | 