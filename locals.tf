locals {
  primary_serial      = [for s in data.cato_accountSnapshotSite.azure-site.info.sockets : s.serial if s.is_primary == true]
  secondary_serial    = [for s in data.cato_accountSnapshotSite.azure-site-secondary.info.sockets : s.serial if s.is_primary == false]
  lan_first_ip        = cidrhost(var.subnet_range_lan, 1)
  resource_group_name = var.create_resource_group ? azurerm_resource_group.azure-rg[0].name : var.resource_group_name
  vnet_name           = var.create_vnet ? azurerm_virtual_network.vnet[0].name : var.vnet_name
  vnet_id             = var.create_vnet ? azurerm_virtual_network.vnet[0].id : data.azurerm_virtual_network.this[0].id
}
