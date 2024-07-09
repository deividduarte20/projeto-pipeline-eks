variable "project_name" {
  type        = string
  description = "Project Name to be used in Tags"
}

variable "tags" {
  type        = map(any)
  description = "Tags to be added to AWS resources"
}

variable "public_subnet_1a" {
  type        = string
  description = "Subnet to create eks cluster AZ 1a"
}

variable "public_subnet_1b" {
  type        = string
  description = "Subnet to create eks cluster AZ 1b"
}