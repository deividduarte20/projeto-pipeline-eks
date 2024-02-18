variable "name-cluster" {
  default = "$cluster_n"
}

variable "instance-type" {
  default = "t3a.medium"
}

variable "instance-ami" {
  default = "ami-04cb4ca688797756f"
}

variable "name-sg" {
  default = "allow_tls"
}

variable "cluster-version" {
  default = "1.29"
}

variable "region" {
  default = "us-east-1"
}