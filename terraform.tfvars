# Basic infra values
resource_group_name = "rg-3tier"
location            = "East US"
vnet_name           = "vnet-3tier"
vnet_address_space  = ["10.0.0.0/16"]

# Subnets
subnet_web_prefix = "10.0.1.0/24"
subnet_app_prefix = "10.0.2.0/24"
subnet_db_prefix  = "10.0.3.0/24"

# VM and access
admin_username       = "azureuser"
ssh_public_key_path  = "C:/Users/rajbh/.ssh/id_rsa.pub"
custom_data_path     = "./customdata.sh"

web_vm_size = "Standard_B1s"
app_vm_size = "Standard_B1s"
db_vm_size  = "Standard_B1s"

# Load balancer and public IP names
web_public_ip_name     = "web-public-ip"
web_lb_public_ip_name  = "web-lb-public-ip"
web_lb_name            = "web-lb"
app_lb_name            = "app-lb-internal"

# Health probe ports
app_health_probe_port = 8080
web_probe_port        = 80

# Tags (optional overrides)
tags = {
  Project     = "terraform-3tier"
  Environment = "dev"
  Owner       = "rajbh"
}
