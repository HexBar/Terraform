# Variables
variable "project_name" {
  type        = string
  default     = "final-project"
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

