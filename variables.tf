############################################
# Inputs for terraform-3tier-azure project
############################################

variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
  default     = "rg-3tier"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "vnet_name" {
  description = "Virtual Network name"
  type        = string
  default     = "vnet-3tier"
}

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_web_prefix" {
  description = "Web subnet prefix"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_app_prefix" {
  description = "App subnet prefix"
  type        = string
  default     = "10.0.2.0/24"
}

variable "subnet_db_prefix" {
  description = "DB subnet prefix"
  type        = string
  default     = "10.0.3.0/24"
}

variable "admin_username" {
  description = "Admin username for all VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file (full path). This file content is used as admin public key."
  type        = string
  default     = "C:/Users/rajbh/.ssh/id_rsa.pub"
}

variable "custom_data_path" {
  description = "Path to the customdata.sh bootstrap script"
  type        = string
  default     = "./customdata.sh"
}

variable "web_vm_size" {
  description = "Size of the Web VM"
  type        = string
  default     = "Standard_B1s"
}

variable "app_vm_size" {
  description = "Size of the App VM"
  type        = string
  default     = "Standard_B1s"
}

variable "db_vm_size" {
  description = "Size of the DB VM"
  type        = string
  default     = "Standard_B1s"
}

variable "web_public_ip_name" {
  description = "Public IP resource name for the Web VM (if created)"
  type        = string
  default     = "web-public-ip"
}

variable "web_lb_public_ip_name" {
  description = "Public IP name for the public Load Balancer"
  type        = string
  default     = "web-lb-public-ip"
}

variable "web_lb_name" {
  description = "Name of the public load balancer"
  type        = string
  default     = "web-lb"
}

variable "app_lb_name" {
  description = "Name of the internal app load balancer"
  type        = string
  default     = "app-lb-internal"
}

variable "app_health_probe_port" {
  description = "App health probe port"
  type        = number
  default     = 8080
}

variable "web_probe_port" {
  description = "Web health probe port"
  type        = number
  default     = 80
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {
    Project     = "terraform-3tier"
    Environment = "dev"
    Owner       = "rajbh"
  }
}
