output "vpc_cidrblock" {
  description = "Range ip da VPC"
  value       = aws_vpc.vpc.cidr_block
}

output "vpc" {
  description = "Idendificador da VPC"
  value       = aws_vpc.vpc.id
}

output "public_subnet" {
  description = "IDs das subnets publicas"
  value       = aws_subnet.public[*].id
}

output "private_subnet" {
  description = "IDs das subnets privadas"
  value       = aws_subnet.private[*].id
}

output "vpc_arn" {
  description = "ARN da VPC"
  value       = aws_vpc.vpc.arn
}

output "igw_id" {
  description = "ID do Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "igw_arn" {
  description = "ARN do Internet Gateway"
  value       = aws_internet_gateway.igw.arn
}



output "nat_ids" {
  description = "Lisa de allocation ID de Elastic IPs criados para AWS NAT Gateway"
  value       = aws_eip.nat_eip[*].id
}



output "natgw_ids" {
  description = "ID do Nat Gateway"
  value       = aws_nat_gateway.nat_gateway[*].id
}

output "natgw_interface_ids" {
  description = "ID da interface associada ao NAT Gateways"
  value       = aws_nat_gateway.nat_gateway[*].network_interface_id
}