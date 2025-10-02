provider "azurerm" {
  subscription_id = var.azure_subscription_id
  features {}
}

provider "cato" {
  baseurl    = var.baseurl
  token      = var.token
  account_id = var.account_id
}

variable "azure_subscription_id" {
  default = "d21d8fbe-3b19-4c0c-86d2-b7dd4f9b93a4"
}

variable "baseurl" {}
variable "token" {}
variable "account_id" {}




module "vsocket-azure-ha-vnet-2nic" {
  source                          = "../"
  token                           = var.token
  account_id                      = var.account_id
  azure_subscription_id           = var.azure_subscription_id
  baseurl                         = var.baseurl
  location                        = "West Europe"
  vnet_name                       = "jr-test-vnet" # Required for both creating or using existing VNET
  resource_group_name             = "jr-test-rg"
  create_resource_group           = true # Set to false if you want to deploy to existing Resource Group and provide current name to resource_group_name
  create_vnet                     = true
  vnet_prefix                     = "10.113.0.0/16"
  subnet_range_wan                = "10.113.2.0/24"
  subnet_range_lan                = "10.113.3.128/25"
  lan_ip_primary                  = "10.113.3.135"
  lan_ip_secondary                = "10.113.3.136"
  floating_ip                     = "10.113.3.137"
  enable_static_range_translation = true
  routed_networks = {
    "Peered-VNET-1" = {
      subnet = "10.100.1.0/24"
    }
    "On-Prem-Network-With-NAT" = {
      subnet            = "192.168.51.0/24"
      translated_subnet = "10.250.3.0/24" # Example translated range
    }
  }

  upstream_bandwidth   = 1000
  downstream_bandwidth = 1000
  site_name            = "jr-test-site-ha-2nic"
  site_description     = "jr-test-site-ha-2nic"
  tags = {
    example_key = "example_value"
    terraform   = "true"
    git_repo    = "https://github.com/catonetworks/terraform-cato-vsocket-azure-ha-vnet-2nic"
  }
}


