data "azurerm_resource_group" "data-azure-rg" {
  name = local.resource_group_name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
}

data "cato_accountSnapshotSite" "azure-site" {
  id = cato_socket_site.azure-site.id
}

data "cato_accountSnapshotSite" "azure-site-secondary" {
  depends_on = [time_sleep.sleep_30_seconds]
  id         = cato_socket_site.azure-site.id
}

data "azurerm_network_interface" "wannicmac-2" {
  name                = "${var.site_name}-wanSecondary"
  resource_group_name = local.resource_group_name
  depends_on          = [time_sleep.sleep_5_seconds-2]
}

data "azurerm_network_interface" "lannicmac-2" {
  name                = "${var.site_name}-lanSecondary"
  resource_group_name = local.resource_group_name
  depends_on          = [time_sleep.sleep_5_seconds-2]
}

data "cato_accountSnapshotSite" "azure-site-2" {
  id         = cato_socket_site.azure-site.id
  depends_on = [time_sleep.sleep_before_delete]
}

data "azurerm_virtual_network" "this" {
  count               = !var.create_vnet ? 1 : 0
  name                = local.vnet_name
  resource_group_name = local.resource_group_name
}