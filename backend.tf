terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstate3tier"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
