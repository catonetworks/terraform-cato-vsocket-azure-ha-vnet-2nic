locals {
  primary_serial                    = [for s in data.cato_accountSnapshotSite.azure-site.info.sockets : s.serial if s.is_primary == true]
  secondary_serial                  = [for s in data.cato_accountSnapshotSite.azure-site-secondary.info.sockets : s.serial if s.is_primary == false]
  lan_first_ip                      = cidrhost(var.subnet_range_lan, 1)
  resource_group_name               = var.create_resource_group ? azurerm_resource_group.azure-rg[0].name : var.resource_group_name
  vnet_name                         = var.create_vnet ? azurerm_virtual_network.vnet[0].name : var.vnet_name
  vnet_id                           = var.create_vnet ? azurerm_virtual_network.vnet[0].id : data.azurerm_virtual_network.this[0].id
  vsocket_primary_name_local        = var.vsocket_primary_name != null ? var.vsocket_primary_name : "Cato-vSocket-Primary"
  vsocket_secondary_name_local      = var.vsocket_secondary_name != null ? var.vsocket_secondary_name : "Cato-vSocket-Secondary"
  wan_subnet_name_local             = var.wan_subnet_name != null ? var.wan_subnet_name : "${local.resource_name_prefix}-subnetWAN"
  lan_subnet_name_local             = var.lan_subnet_name != null ? var.lan_subnet_name : "${local.resource_name_prefix}-subnetLAN"
  ha_identity_name_local            = var.ha_identity_name != null ? var.ha_identity_name : "${local.resource_name_prefix}-CatoHaIdentity"
  vsocket_primary_disk_name_local   = var.vsocket_primary_disk_name != null ? var.vsocket_primary_disk_name : "${local.resource_name_prefix}-vSocket-disk-primary"
  vsocket_secondary_disk_name_local = var.vsocket_secondary_disk_name != null ? var.vsocket_secondary_disk_name : "${local.resource_name_prefix}-vSocket-disk-secondary"
  resource_name_prefix              = var.resource_prefix_name == null ? var.site_name : var.resource_prefix_name
}

locals {
  # JSON content for /cato/nics_config.json
  nics_config = jsonencode({
    wan_nic     = azurerm_network_interface.wan-nic-primary.name
    wan_nic_mac = lower(replace(data.azurerm_network_interface.wannicmac.mac_address, "-", ":"))
    wan_nic_ip  = azurerm_network_interface.wan-nic-primary.private_ip_address

    lan_nic     = azurerm_network_interface.lan-nic-primary.name
    lan_nic_mac = lower(replace(data.azurerm_network_interface.lannicmac.mac_address, "-", ":"))
    lan_nic_ip  = azurerm_network_interface.lan-nic-primary.private_ip_address
  })

  # JSON content for /cato/socket/configuration/vm_config.json
  vm_config = jsonencode({
    location        = var.location
    subscription_id = var.azure_subscription_id
    vnet            = var.vnet_name
    group           = var.resource_group_name
    vnet_group      = var.resource_group_name
    subnet          = azurerm_subnet.subnet-lan.name
    nic             = azurerm_network_interface.lan-nic-primary.name
    ha_nic          = azurerm_network_interface.lan-nic-secondary.name
    lan_nic_ip      = azurerm_network_interface.lan-nic-primary.private_ip_address
    lan_nic_mac     = lower(replace(data.azurerm_network_interface.lannicmac.mac_address, "-", ":"))
    subnet_cidr     = var.subnet_range_lan
    az_mgmt_url     = "management.azure.com"
  })

  # If we put JSON inside single quotes in bash, guard against a rare `'` in any value.
  nics_config_shell = replace(local.nics_config, "'", "'\\''")
  vm_config_shell   = replace(local.vm_config, "'", "'\\''")

  # Build the final command the extension runs
  primary_command = join("; ", compact([
    "echo '${local.primary_serial[0]}' > /cato/serial.txt",
    "echo '${local.nics_config_shell}' > /cato/nics_config.json",
    "echo '${local.vm_config_shell}' > /cato/socket/configuration/vm_config.json",
    join(";", var.commands),
  ]))
}

locals {
  # JSON content for /cato/nics_config.json (SECONDARY)
  nics_config_secondary = jsonencode({
    wan_nic     = azurerm_network_interface.wan-nic-secondary.name
    wan_nic_mac = lower(replace(data.azurerm_network_interface.wannicmac-2.mac_address, "-", ":"))
    wan_nic_ip  = azurerm_network_interface.wan-nic-secondary.private_ip_address

    lan_nic     = azurerm_network_interface.lan-nic-secondary.name
    lan_nic_mac = lower(replace(data.azurerm_network_interface.lannicmac-2.mac_address, "-", ":"))
    lan_nic_ip  = azurerm_network_interface.lan-nic-secondary.private_ip_address
  })

  # JSON content for /cato/socket/configuration/vm_config.json (SECONDARY)
  vm_config_secondary = jsonencode({
    location        = var.location
    subscription_id = var.azure_subscription_id
    vnet            = var.vnet_name
    group           = var.resource_group_name
    vnet_group      = var.resource_group_name
    subnet          = azurerm_subnet.subnet-lan.name
    nic             = azurerm_network_interface.lan-nic-secondary.name
    ha_nic          = azurerm_network_interface.lan-nic-primary.name
    lan_nic_ip      = azurerm_network_interface.lan-nic-secondary.private_ip_address
    lan_nic_mac     = lower(replace(data.azurerm_network_interface.lannicmac-2.mac_address, "-", ":"))
    subnet_cidr     = var.subnet_range_lan
    az_mgmt_url     = "management.azure.com"
  })

  # Guard against rare single-quotes in values (since we wrap JSON in single quotes in the shell)
  nics_config_secondary_shell = replace(local.nics_config_secondary, "'", "'\\''")
  vm_config_secondary_shell   = replace(local.vm_config_secondary, "'", "'\\''")

  # Final command executed on SECONDARY
  secondary_command = join("; ", compact([
    "echo '${local.secondary_serial[0]}' > /cato/serial.txt",
    "echo '${local.nics_config_secondary_shell}' > /cato/nics_config.json",
    "echo '${local.vm_config_secondary_shell}' > /cato/socket/configuration/vm_config.json",
    join(";", var.commands),
  ]))
}