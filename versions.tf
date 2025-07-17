terraform {
  required_providers {
    cato = {
      source  = "catonetworks/cato"
      version = ">= 0.0.30"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.34"
    }
  }
  required_version = ">= 1.4"
}
