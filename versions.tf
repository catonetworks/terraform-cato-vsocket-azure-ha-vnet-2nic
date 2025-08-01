terraform {
  required_providers {
    cato = {
      source  = "catonetworks/cato"
      version = ">= 0.0.38"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.33.0"
    }
  }
  required_version = ">= 1.4"
}
