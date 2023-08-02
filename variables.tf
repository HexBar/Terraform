# Variables
variable "project_name" {
  type        = string
  default     = "WeightTracker"
  description = "Project Name"
}

variable "resource_group_name" {
  type        = string
  default     = "rg-"
  description = "Resource Group Name"
}

variable "virtual_network_name" {
  type        = string
  default     = "vnet-"
  description = "Virtual Network Name"
}

variable "subnet_name" {
  type        = string
  default     = "snet-"
  description = "Subnet Name"
}

variable "network_security_group_name" {
  type        = string
  default     = "nsg-"
  description = "Network Security Group Name"
}

variable "web_subnet_mask" {
  type        = string
  default     = "10.0.1.0/24"
  description = "Web Subnet Mask"
}

variable "db_subnet_mask" {
  type        = string
  default     = "10.0.2.0/24"
  description = "Database Subnet Mask"
}

variable "vm_name" {
  type        = string
  default     = "vm-"
  description = "Virtual Machine Name"
}