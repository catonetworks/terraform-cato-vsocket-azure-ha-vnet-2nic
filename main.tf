resource "random_string" "vsocket-random-username" {
  length  = 16
  special = false
}

resource "random_string" "vsocket-random-password" {
  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}
## VNET Module Resources
resource "azurerm_resource_group" "azure-rg" {
  count    = var.create_resource_group ? 1 : 0
  location = var.location
  name     = var.resource_group_name
  tags     = var.tags
}

resource "azurerm_availability_set" "availability-set" {
  location                     = var.location
  name                         = "${var.resource_prefix_name}-availabilitySet"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  resource_group_name          = local.resource_group_name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
  tags = var.tags
}

## Create Network and Subnets
resource "azurerm_virtual_network" "vnet" {
  count         = var.create_vnet ? 1 : 0
  address_space = [var.vnet_prefix]
  location      = var.location
  name          = var.vnet_name == null ? "${var.resource_prefix_name}-vnet" : var.vnet_name

  resource_group_name = local.resource_group_name
  depends_on = [
    data.azurerm_resource_group.data-azure-rg
  ]
  tags = var.tags
}

resource "azurerm_virtual_network_dns_servers" "dns_servers" {
  virtual_network_id = local.vnet_id
  dns_servers        = var.dns_servers
}

resource "azurerm_subnet" "subnet-wan" {
  address_prefixes     = [var.subnet_range_wan]
  name                 = local.wan_subnet_name_local
  resource_group_name  = local.resource_group_name
  virtual_network_name = var.vnet_name
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "subnet-lan" {
  address_prefixes     = [var.subnet_range_lan]
  name                 = local.lan_subnet_name_local
  resource_group_name  = local.resource_group_name
  virtual_network_name = var.vnet_name
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_public_ip" "wan-public-ip-primary" {
  allocation_method   = "Static"
  location            = var.location
  name                = "${var.resource_prefix_name}-wanPublicIPPrimary"
  resource_group_name = local.resource_group_name
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
  tags = var.tags
}

resource "azurerm_public_ip" "wan-public-ip-secondary" {
  allocation_method   = "Static"
  location            = var.location
  name                = "${var.resource_prefix_name}-wanPublicIPSecondary"
  resource_group_name = local.resource_group_name
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
  tags = var.tags
}

# Create Network Interfaces
resource "azurerm_network_interface" "wan-nic-primary" {
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true
  location                       = var.location
  name                           = "${var.resource_prefix_name}-wanPrimary"
  resource_group_name            = local.resource_group_name
  ip_configuration {
    name                          = "${var.resource_prefix_name}-wanIPPrimary"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wan-public-ip-primary.id
    subnet_id                     = azurerm_subnet.subnet-wan.id
  }
  depends_on = [
    azurerm_public_ip.wan-public-ip-primary,
    azurerm_subnet.subnet-wan
  ]
  tags = var.tags
}


resource "azurerm_network_interface" "lan-nic-primary" {
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true
  location                       = var.location
  name                           = "${var.resource_prefix_name}-lanPrimary"
  resource_group_name            = local.resource_group_name
  ip_configuration {
    name                          = "${var.resource_prefix_name}-lanIPConfigPrimary"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lan_ip_primary
    subnet_id                     = azurerm_subnet.subnet-lan.id
  }
  depends_on = [
    azurerm_subnet.subnet-lan
  ]
  lifecycle {
    ignore_changes = [ip_configuration] #Ignoring Changes because the Floating IP will move based on Active Device
  }
  tags = var.tags
}

resource "azurerm_network_interface" "wan-nic-secondary" {
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true
  location                       = var.location
  name                           = "${var.resource_prefix_name}-wanSecondary"
  resource_group_name            = local.resource_group_name
  ip_configuration {
    name                          = "${var.resource_prefix_name}-wanIPSecondary"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wan-public-ip-secondary.id
    subnet_id                     = azurerm_subnet.subnet-wan.id
  }
  depends_on = [
    azurerm_public_ip.wan-public-ip-secondary,
    azurerm_subnet.subnet-wan
  ]
  tags = var.tags
}

resource "azurerm_network_interface" "lan-nic-secondary" {
  ip_forwarding_enabled          = true
  accelerated_networking_enabled = true
  location                       = var.location
  name                           = "${var.resource_prefix_name}-lanSecondary"
  resource_group_name            = local.resource_group_name
  ip_configuration {
    name                          = "${var.resource_prefix_name}-lanIPConfigSecondary"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lan_ip_secondary
    subnet_id                     = azurerm_subnet.subnet-lan.id
  }
  depends_on = [
    azurerm_subnet.subnet-lan
  ]

  lifecycle {
    ignore_changes = [ip_configuration] #Ignoring Changes because the Floating IP will move based on Active Device
  }
  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "wan-association" {
  subnet_id                 = azurerm_subnet.subnet-wan.id
  network_security_group_id = azurerm_network_security_group.wan-sg.id
}

resource "azurerm_subnet_network_security_group_association" "lan-association" {
  subnet_id                 = azurerm_subnet.subnet-lan.id
  network_security_group_id = azurerm_network_security_group.lan-sg.id
}

# Create Security Groups
resource "azurerm_network_security_group" "wan-sg" {
  location            = var.location
  name                = "${var.resource_prefix_name}-WANSecurityGroup"
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "Allow-DNS-TCP"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "Allow-DNS-UDP"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "53"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "Allow-HTTPS-TCP"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "Allow-HTTPS-UDP"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "Deny-All-Outbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  depends_on = [
    azurerm_resource_group.azure-rg
  ]
  tags = var.tags
}

resource "azurerm_network_security_group" "lan-sg" {
  location            = var.location
  name                = "${var.resource_prefix_name}-LANSecurityGroup"
  resource_group_name = local.resource_group_name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
  tags = var.tags
}

# Create Route Tables, Routes and Associations 
resource "azurerm_route_table" "private-rt" {
  bgp_route_propagation_enabled = false
  location                      = var.location
  name                          = "${var.resource_prefix_name}-viaCato"
  resource_group_name           = local.resource_group_name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
  tags = var.tags
}

resource "azurerm_route" "public-rt" {
  address_prefix      = "23.102.135.246/32" #
  name                = "Microsoft-KMS"
  next_hop_type       = "Internet"
  resource_group_name = local.resource_group_name
  route_table_name    = "${var.resource_prefix_name}-viaCato"
  depends_on = [
    azurerm_route_table.private-rt
  ]
}

resource "azurerm_route" "lan-route" {
  address_prefix         = "0.0.0.0/0"
  name                   = "default-cato"
  next_hop_in_ip_address = var.floating_ip
  next_hop_type          = "VirtualAppliance"
  resource_group_name    = local.resource_group_name
  route_table_name       = "${var.resource_prefix_name}-viaCato"
  depends_on = [
    azurerm_route_table.private-rt
  ]
}

resource "azurerm_route_table" "public-rt" {
  bgp_route_propagation_enabled = false
  location                      = var.location
  name                          = "${var.resource_prefix_name}-viaInternet"
  resource_group_name           = local.resource_group_name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
  tags = var.tags
}

resource "azurerm_route" "route-internet" {
  address_prefix      = "0.0.0.0/0"
  name                = "default-internet"
  next_hop_type       = "Internet"
  resource_group_name = local.resource_group_name
  route_table_name    = "${var.resource_prefix_name}-viaInternet"
  depends_on = [
    azurerm_route_table.public-rt
  ]
}

resource "azurerm_subnet_route_table_association" "rt-table-association-wan" {
  route_table_id = azurerm_route_table.public-rt.id
  subnet_id      = azurerm_subnet.subnet-wan.id
  depends_on = [
    azurerm_route_table.public-rt,
    azurerm_subnet.subnet-wan,
  ]
}

resource "azurerm_subnet_route_table_association" "rt-table-association-lan" {
  route_table_id = azurerm_route_table.private-rt.id
  subnet_id      = azurerm_subnet.subnet-lan.id
  depends_on = [
    azurerm_route_table.private-rt,
    azurerm_subnet.subnet-lan
  ]
}

resource "cato_socket_site" "azure-site" {
  connection_type = "SOCKET_AZ1500"
  description     = var.site_description
  name            = var.site_name
  native_range = {
    native_network_range = var.native_network_range == null ? var.subnet_range_lan : var.native_network_range
    local_ip             = azurerm_network_interface.lan-nic-primary.private_ip_address
  }
  site_location = local.cur_site_location
  site_type     = var.site_type
}



# Create HA user Assigned Identity
resource "azurerm_user_assigned_identity" "CatoHaIdentity" {
  resource_group_name = local.resource_group_name
  location            = var.location
  name                = local.ha_identity_name_local
  tags                = var.tags
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
}

# Create Primary Vsocket Virtual Machine
resource "azurerm_linux_virtual_machine" "vsocket_primary" {
  location              = var.location
  name                  = local.vsocket_primary_name_local
  computer_name         = local.vsocket_primary_name_local
  size                  = var.vm_size
  network_interface_ids = [azurerm_network_interface.wan-nic-primary.id, azurerm_network_interface.lan-nic-primary.id]
  resource_group_name   = local.resource_group_name

  availability_set_id = var.availability_set_id
  zone                = var.vsocket_primary_zone

  disable_password_authentication = false
  provision_vm_agent              = true
  allow_extension_operations      = true

  admin_username = random_string.vsocket-random-username.result
  admin_password = "${random_string.vsocket-random-password.result}@"

  # Assign CatoHaIdentity to the Vsocket
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.CatoHaIdentity.id]
  }

  # OS disk configuration from variables
  os_disk {
    name                 = local.vsocket_primary_disk_name_local
    caching              = var.vm_os_disk_config.caching
    storage_account_type = var.vm_os_disk_config.storage_account_type
    disk_size_gb         = var.vm_os_disk_config.disk_size_gb
  }

  # Boot diagnostics controlled by a boolean variable
  boot_diagnostics {
    # An empty string enables managed boot diagnostics. `null` disables the block.
    storage_account_uri = var.enable_boot_diagnostics ? "" : null
  }

  # Plan information from the image configuration variable
  plan {
    name      = var.vm_image_config.sku
    publisher = var.vm_image_config.publisher
    product   = var.vm_image_config.product
  }

  # Source image reference from the image configuration variable
  source_image_reference {
    publisher = var.vm_image_config.publisher
    offer     = var.vm_image_config.offer
    sku       = var.vm_image_config.sku
    version   = var.vm_image_config.version
  }


  depends_on = [
    cato_socket_site.azure-site,
    data.cato_accountSnapshotSite.azure-site,
    data.cato_accountSnapshotSite.azure-site-2
  ]
  tags = var.tags
}


# To allow mac address to be retrieved
resource "time_sleep" "sleep_5_seconds" {
  create_duration = "5s"
  depends_on      = [azurerm_linux_virtual_machine.vsocket_primary]
}

data "azurerm_network_interface" "wannicmac" {
  name                = "${var.resource_prefix_name}-wanPrimary"
  resource_group_name = local.resource_group_name
  depends_on          = [time_sleep.sleep_5_seconds]
}

data "azurerm_network_interface" "lannicmac" {
  name                = "${var.resource_prefix_name}-lanPrimary"
  resource_group_name = local.resource_group_name
  depends_on          = [time_sleep.sleep_5_seconds]
}

variable "commands" {
  type = list(string)
  default = [
    "rm /cato/deviceid.txt",
    "rm /cato/socket/configuration/socket_registration.json",
    "nohup /cato/socket/run_socket_daemon.sh &"
  ]
}

resource "azurerm_virtual_machine_extension" "vsocket-custom-script-primary" {
  auto_upgrade_minor_version = true
  name                       = "vsocket-custom-script-primary"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  virtual_machine_id         = azurerm_linux_virtual_machine.vsocket_primary.id
  lifecycle {
    ignore_changes = all
  }
  settings = <<SETTINGS
{
  "commandToExecute": "echo '${local.primary_serial[0]}' > /cato/serial.txt; echo '{\"wan_nic\":\"${azurerm_network_interface.wan-nic-primary.name}\",\"wan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.wannicmac.mac_address, "-", ":"))}\",\"wan_nic_ip\":\"${azurerm_network_interface.wan-nic-primary.private_ip_address}\",\"lan_nic\":\"${azurerm_network_interface.lan-nic-primary.name}\",\"lan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.lannicmac.mac_address, "-", ":"))}\",\"lan_nic_ip\":\"${azurerm_network_interface.lan-nic-primary.private_ip_address}\"}' > /cato/nics_config.json; ${join(";", var.commands)}"
}
SETTINGS

  depends_on = [
    azurerm_linux_virtual_machine.vsocket_primary,
    data.azurerm_network_interface.lannicmac,
    data.azurerm_network_interface.wannicmac
  ]
  tags = var.tags
}

# To allow socket to upgrade, so secondary socket can be added
resource "time_sleep" "sleep_300_seconds" {
  create_duration = "300s"
  depends_on      = [azurerm_virtual_machine_extension.vsocket-custom-script-primary]
}

#################################################################################
# Add secondary socket to site via API until socket_site resource is updated to natively support


# Sleep to allow Secondary vSocket serial retrieval
resource "time_sleep" "sleep_30_seconds" {
  create_duration = "30s"
  depends_on      = [terraform_data.configure_secondary_azure_vsocket]
}

# Create Primary Vsocket Virtual Machine
resource "azurerm_linux_virtual_machine" "vsocket_secondary" {
  location              = var.location
  name                  = local.vsocket_secondary_name_local
  computer_name         = local.vsocket_secondary_name_local
  size                  = var.vm_size
  network_interface_ids = [azurerm_network_interface.wan-nic-secondary.id, azurerm_network_interface.lan-nic-secondary.id]
  resource_group_name   = local.resource_group_name

  availability_set_id = var.availability_set_id
  zone                = var.vsocket_secondary_zone

  disable_password_authentication = false
  provision_vm_agent              = true
  allow_extension_operations      = true

  admin_username = random_string.vsocket-random-username.result
  admin_password = "${random_string.vsocket-random-password.result}@"

  # Assign CatoHaIdentity to the Vsocket
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.CatoHaIdentity.id]
  }

  # OS disk configuration from image
  os_disk {
    name                 = local.vsocket_secondary_disk_name_local
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 8
  }

  # Boot diagnostics
  boot_diagnostics {
    storage_account_uri = "" # Empty string enables boot diagnostics
  }

  plan {
    name      = "public-cato-socket"
    publisher = "catonetworks"
    product   = "cato_socket"
  }

  source_image_reference {
    publisher = "catonetworks"
    offer     = "cato_socket"
    sku       = "public-cato-socket"
    version   = "23.0.19605"
  }


  depends_on = [
    data.cato_accountSnapshotSite.azure-site-secondary,
    terraform_data.configure_secondary_azure_vsocket,
    data.cato_accountSnapshotSite.azure-site-2
  ]
  tags = var.tags
}


#Sleep to allow Secondary vSocket interface mac address retrieval
resource "time_sleep" "sleep_5_seconds-2" {
  create_duration = "5s"
  depends_on      = [azurerm_linux_virtual_machine.vsocket_secondary]
}

resource "azurerm_virtual_machine_extension" "vsocket-custom-script-secondary" {
  auto_upgrade_minor_version = true
  name                       = "vsocket-custom-script-secondary"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  virtual_machine_id         = azurerm_linux_virtual_machine.vsocket_secondary.id
  lifecycle {
    ignore_changes = all
  }
  settings = <<SETTINGS
 {
  "commandToExecute": "echo '${local.secondary_serial[0]}' > /cato/serial.txt; echo '{\"wan_nic\":\"${azurerm_network_interface.wan-nic-secondary.name}\",\"wan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.wannicmac-2.mac_address, "-", ":"))}\",\"wan_nic_ip\":\"${azurerm_network_interface.wan-nic-secondary.private_ip_address}\",\"lan_nic\":\"${azurerm_network_interface.lan-nic-secondary.name}\",\"lan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.lannicmac-2.mac_address, "-", ":"))}\",\"lan_nic_ip\":\"${azurerm_network_interface.lan-nic-secondary.private_ip_address}\"}' > /cato/nics_config.json; ${join(";", var.commands)}"
 }
SETTINGS
  depends_on = [
    azurerm_linux_virtual_machine.vsocket_secondary
  ]
  tags = var.tags
}

# Configure Secondary Azure vSocket via API
resource "terraform_data" "configure_secondary_azure_vsocket" {
  depends_on = [time_sleep.sleep_300_seconds]

  provisioner "local-exec" {
    # This command is generated from a template to keep the main file clean.
    # It sends a GraphQL mutation to an API endpoint.
    command = templatefile("${path.module}/templates/configure_secondary_azure_vsocket.tftpl", {
      api_token    = var.token
      base_url     = var.baseurl
      account_id   = var.account_id
      floating_ip  = var.floating_ip
      interface_ip = azurerm_network_interface.lan-nic-secondary.private_ip_address
      site_id      = cato_socket_site.azure-site.id
    })
  }

  triggers_replace = {
    account_id = var.account_id
    site_id    = cato_socket_site.azure-site.id
  }
}


# Create HA Settings Secondary
resource "terraform_data" "run_command_ha_primary" {
  provisioner "local-exec" {
    # This command is now generated from a template file.
    # The templatefile() function reads the template and injects the variables.
    command = templatefile("${path.module}/templates/run_command_ha_primary.tftpl", {
      resource_group_name  = data.azurerm_resource_group.data-azure-rg.name
      vsocket_primary_name = local.vsocket_primary_name_local
      location             = var.location
      subscription_id      = var.azure_subscription_id
      vnet_name            = var.vnet_name
      subnet_name          = azurerm_subnet.subnet-lan.name
      primary_nic_name     = azurerm_network_interface.lan-nic-primary.name
      secondary_nic_name   = azurerm_network_interface.lan-nic-secondary.name
      primary_nic_ip       = azurerm_network_interface.lan-nic-primary.private_ip_address
      primary_nic_mac      = azurerm_network_interface.lan-nic-primary.mac_address
      subnet_range_lan     = var.subnet_range_lan
    })
  }

  depends_on = [
    azurerm_virtual_machine_extension.vsocket-custom-script-secondary
  ]
}

resource "terraform_data" "run_command_ha_secondary" {
  provisioner "local-exec" {
    # This command is also generated from its own template file.
    command = templatefile("${path.module}/templates/run_command_ha_secondary.tftpl", {
      resource_group_name    = data.azurerm_resource_group.data-azure-rg.name
      vsocket_secondary_name = local.vsocket_secondary_name_local
      location               = var.location
      subscription_id        = var.azure_subscription_id
      vnet_name              = var.vnet_name
      subnet_name            = azurerm_subnet.subnet-lan.name
      primary_nic_name       = azurerm_network_interface.lan-nic-primary.name
      secondary_nic_name     = azurerm_network_interface.lan-nic-secondary.name
      secondary_nic_ip       = azurerm_network_interface.lan-nic-secondary.private_ip_address
      secondary_nic_mac      = azurerm_network_interface.lan-nic-secondary.mac_address
      subnet_range_lan       = var.subnet_range_lan
    })
  }

  depends_on = [
    azurerm_virtual_machine_extension.vsocket-custom-script-secondary
  ]
}

# Reboot Primary vSocket
resource "terraform_data" "reboot_vsocket_primary" {
  provisioner "local-exec" {
    # The simple restart command is also templated for consistency.
    command = templatefile("${path.module}/templates/reboot_vsocket_primary.tftpl", {
      resource_group_name  = data.azurerm_resource_group.data-azure-rg.name
      vsocket_primary_name = local.vsocket_primary_name_local
    })
  }

  depends_on = [
    terraform_data.run_command_ha_secondary
  ]
}

# Reboot Secondary vSocket
resource "terraform_data" "reboot_vsocket_secondary" {
  provisioner "local-exec" {
    # Templating the secondary restart command.
    command = templatefile("${path.module}/templates/reboot_vsocket_secondary.tftpl", {
      resource_group_name    = data.azurerm_resource_group.data-azure-rg.name
      vsocket_secondary_name = local.vsocket_secondary_name_local
    })
  }

  depends_on = [
    terraform_data.run_command_ha_secondary
  ]
}

# Role assignments for secondary lan nic and subnet
resource "azurerm_role_assignment" "secondary_nic_ha_role" {
  principal_id         = azurerm_user_assigned_identity.CatoHaIdentity.principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope                = azurerm_network_interface.lan-nic-secondary.id
  depends_on           = [azurerm_linux_virtual_machine.vsocket_secondary]
}

resource "azurerm_role_assignment" "lan-subnet-role" {
  principal_id         = azurerm_user_assigned_identity.CatoHaIdentity.principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope                = "/subscriptions/${var.azure_subscription_id}/resourcegroups/${data.azurerm_resource_group.data-azure-rg.name}/providers/Microsoft.Network/virtualNetworks/${var.vnet_name}/subnets/${azurerm_subnet.subnet-lan.name}"
  depends_on           = [azurerm_user_assigned_identity.CatoHaIdentity]
}

#Temporary role assignments for primary
resource "azurerm_role_assignment" "primary_nic_ha_role" {
  principal_id         = azurerm_user_assigned_identity.CatoHaIdentity.principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope                = "/subscriptions/${var.azure_subscription_id}/resourcegroups/${data.azurerm_resource_group.data-azure-rg.name}/providers/Microsoft.Network/networkInterfaces/${azurerm_network_interface.lan-nic-primary.name}"
  depends_on           = [azurerm_user_assigned_identity.CatoHaIdentity]
}

# Time delay to allow for vsockets to upgrade
resource "time_sleep" "delay" {
  create_duration = "10s"
  depends_on      = [terraform_data.run_command_ha_secondary]
}

# Time delay to allow for vsockets HA to complete configuration
resource "time_sleep" "delay-ha" {
  create_duration = "75s"
  depends_on      = [terraform_data.reboot_vsocket_secondary]
}

# Allow vSocket to be disconnected to delete site
resource "time_sleep" "sleep_before_delete" {
  destroy_duration = "30s"
}

resource "cato_network_range" "routedAzure" {
  for_each   = var.routed_networks
  site_id    = cato_socket_site.azure-site.id
  name       = each.key # The name is the key from the map item.
  range_type = "Routed"
  gateway    = var.routed_ranges_gateway == null ? local.lan_first_ip : var.routed_ranges_gateway
  subnet     = each.value # The subnet is the value from the map item.
}

# Update socket Bandwidth
resource "cato_wan_interface" "wan" {
  site_id              = cato_socket_site.azure-site.id
  interface_id         = "WAN1"
  name                 = "WAN 1"
  upstream_bandwidth   = var.upstream_bandwidth
  downstream_bandwidth = var.downstream_bandwidth
  role                 = "wan_1"
  precedence           = "ACTIVE"
}

# Cato license resource
resource "cato_license" "license" {
  depends_on = [terraform_data.reboot_vsocket_secondary]
  count      = var.license_id == null ? 0 : 1
  site_id    = cato_socket_site.azure-site.id
  license_id = var.license_id
  bw         = var.license_bw == null ? null : var.license_bw
}
