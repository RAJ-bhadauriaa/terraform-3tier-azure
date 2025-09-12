###########################
# outputs.tf
###########################

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.rg.name
}

# Public IPs
output "web_vm_public_ip" {
  description = "Public IP address assigned to the Web VM (web-public-ip)"
  value       = azurerm_public_ip.web_public_ip.ip_address
}

output "web_lb_public_ip" {
  description = "Public IP of the Web Load Balancer"
  value       = azurerm_public_ip.web_lb_public_ip.ip_address
}

# Private IPs (from NIC ip_configuration blocks)
output "web_vm_private_ip" {
  description = "Private IP of web VM (NIC)"
  value       = azurerm_network_interface.web_nic.ip_configuration[0].private_ip_address
}

output "app_vm_private_ip" {
  description = "Private IP of app VM (NIC)"
  value       = azurerm_network_interface.app_nic.ip_configuration[0].private_ip_address
}

output "db_vm_private_ip" {
  description = "Private IP of db VM (NIC)"
  value       = azurerm_network_interface.db_nic.ip_configuration[0].private_ip_address
}

# Internal LB frontend IP (App LB)
output "app_lb_frontend_private_ip" {
  description = "Private frontend IP of the internal App Load Balancer"
  value       = try(azurerm_lb.app_lb.frontend_ip_configuration[0].private_ip_address, "")
}

# Load Balancer backend pool IDs (handy for troubleshooting / integrations)
output "web_lb_backend_pool_id" {
  description = "ID of the Web LB backend address pool"
  value       = azurerm_lb_backend_address_pool.web_backend_pool.id
}

output "app_lb_backend_pool_id" {
  description = "ID of the App internal LB backend address pool"
  value       = azurerm_lb_backend_address_pool.app_backend_pool.id
}

# Helpful SSH connection string for the web VM
output "web_vm_ssh_command" {
  description = "SSH command to connect to Web VM (uses default key ~/.ssh/id_rsa). Replace path if different."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.web_public_ip.ip_address}"
}
