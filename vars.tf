variable "vpc_cidr_block" {
  default     = "10.0.0.0/16"
  description = "CIDR block for VPC."
}

variable "subnet_priv_a_cidr" {
  default     = "10.0.1.0/24"
  description = "CIDR block for private subnet A."
}

variable "subnet_priv_b_cidr" {
  default     = "10.0.2.0/24"
  description = "CIDR block for private subnet B."
}

variable "subnet_priv_c_cidr" {
  default     = "10.0.3.0/24"
  description = "CIDR block for private subnet C."
}

variable "subnet_pub_a_cidr" {
  default     = "10.0.10.0/24"
  description = "CIDR block for public subnet A."
}

variable "subnet_pub_b_cidr" {
  default     = "10.0.11.0/24"
  description = "CIDR block for public subnet B."
}

variable "subnet_pub_c_cidr" {
  default     = "10.0.12.0/24"
  description = "CIDR block for public subnet C."
}
