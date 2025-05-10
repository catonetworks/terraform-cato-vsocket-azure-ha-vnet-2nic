## VNET Module Resources
resource "azurerm_resource_group" "azure-rg" {
  location = var.location
  name     = replace(replace(var.site_name, "-", ""), " ", "_")
}

resource "azurerm_availability_set" "availability-set" {
  location                     = var.location
  name                         = replace(replace("${var.site_name}-availabilitySet", "-", "_"), " ", "_")
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  resource_group_name          = azurerm_resource_group.azure-rg.name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
}

## Create Network and Subnets
resource "azurerm_virtual_network" "vnet" {
  address_space       = [var.vnet_prefix]
  location            = var.location
  name                = replace(replace("${var.site_name}-vsNet", "-", "_"), " ", "_")
  resource_group_name = azurerm_resource_group.azure-rg.name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
}

resource "azurerm_virtual_network_dns_servers" "dns_servers" {
  virtual_network_id = azurerm_virtual_network.vnet.id
  dns_servers        = var.dns_servers
}

resource "azurerm_subnet" "subnet-wan" {
  address_prefixes     = [var.subnet_range_wan]
  name                 = replace(replace("${var.site_name}-subnetWAN", "-", "_"), " ", "_")
  resource_group_name  = azurerm_resource_group.azure-rg.name
  virtual_network_name = replace(replace("${var.site_name}-vsNet", "-", "_"), " ", "_")
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "subnet-lan" {
  address_prefixes     = [var.subnet_range_lan]
  name                 = replace(replace("${var.site_name}-subnetLAN", "-", "_"), " ", "_")
  resource_group_name  = azurerm_resource_group.azure-rg.name
  virtual_network_name = replace(replace("${var.site_name}-vsNet", "-", "_"), " ", "_")
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_public_ip" "wan-public-ip-primary" {
  allocation_method   = "Static"
  location            = var.location
  name                = replace(replace("${var.site_name}-wanPublicIPPrimary", "-", "_"), " ", "_")
  resource_group_name = azurerm_resource_group.azure-rg.name
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
}

resource "azurerm_public_ip" "wan-public-ip-secondary" {
  allocation_method   = "Static"
  location            = var.location
  name                = replace(replace("${var.site_name}-wanPublicIPSecondary", "-", "_"), " ", "_")
  resource_group_name = azurerm_resource_group.azure-rg.name
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
}

# Create Network Interfaces
resource "azurerm_network_interface" "wan-nic-primary" {
  ip_forwarding_enabled = true
  location              = var.location
  name                  = "${var.site_name}-wanPrimary"
  resource_group_name   = azurerm_resource_group.azure-rg.name
  ip_configuration {
    name                          = replace(replace("${var.site_name}-wanIPPrimary", "-", "_"), " ", "_")
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wan-public-ip-primary.id
    subnet_id                     = azurerm_subnet.subnet-wan.id
  }
  depends_on = [
    azurerm_public_ip.wan-public-ip-primary,
    azurerm_subnet.subnet-wan
  ]
}

resource "azurerm_network_interface" "lan-nic-primary" {
  ip_forwarding_enabled          = true
  location                       = var.location
  name                           = "${var.site_name}-lanPrimary"
  resource_group_name            = azurerm_resource_group.azure-rg.name
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = replace(replace("${var.site_name}-lanIPConfigPrimary", "-", "_"), " ", "_")
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lan_ip_primary
    subnet_id                     = azurerm_subnet.subnet-lan.id
  }
  depends_on = [
    azurerm_subnet.subnet-lan
  ]
}

resource "azurerm_network_interface" "wan-nic-secondary" {
  ip_forwarding_enabled          = true
  location                       = var.location
  name                           = "${var.site_name}-wanSecondary"
  resource_group_name            = azurerm_resource_group.azure-rg.name
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = replace(replace("${var.site_name}-wanIPSecondary", "-", "_"), " ", "_")
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wan-public-ip-secondary.id
    subnet_id                     = azurerm_subnet.subnet-wan.id
  }
  depends_on = [
    azurerm_public_ip.wan-public-ip-secondary,
    azurerm_subnet.subnet-wan
  ]
}

resource "azurerm_network_interface" "lan-nic-secondary" {
  ip_forwarding_enabled          = true
  location                       = var.location
  name                           = "${var.site_name}-lanSecondary"
  resource_group_name            = azurerm_resource_group.azure-rg.name
  accelerated_networking_enabled = true
  ip_configuration {
    name                          = replace(replace("${var.site_name}-lanIPConfigSecondary", "-", "_"), " ", "_")
    private_ip_address_allocation = "Static"
    private_ip_address            = var.lan_ip_secondary
    subnet_id                     = azurerm_subnet.subnet-lan.id
  }
  depends_on = [
    azurerm_subnet.subnet-lan
  ]
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
  name                = replace(replace("${var.site_name}-WANSecurityGroup", "-", "_"), " ", "_")
  resource_group_name = azurerm_resource_group.azure-rg.name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
}

resource "azurerm_network_security_group" "lan-sg" {
  location            = var.location
  name                = replace(replace("${var.site_name}-LANSecurityGroup", "-", "_"), " ", "_")
  resource_group_name = azurerm_resource_group.azure-rg.name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
}

# Create Route Tables, Routes and Associations 
resource "azurerm_route_table" "private-rt" {
  bgp_route_propagation_enabled = false
  location                      = var.location
  name                          = replace(replace("${var.site_name}-viaCato", "-", "_"), " ", "_")
  resource_group_name           = azurerm_resource_group.azure-rg.name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
}

resource "azurerm_route" "public-rt" {
  address_prefix      = "23.102.135.246/32" #
  name                = "Microsoft-KMS"
  next_hop_type       = "Internet"
  resource_group_name = azurerm_resource_group.azure-rg.name
  route_table_name    = replace(replace("${var.site_name}-viaCato", "-", "_"), " ", "_")
  depends_on = [
    azurerm_route_table.private-rt
  ]
}

resource "azurerm_route" "lan-route" {
  address_prefix         = "0.0.0.0/0"
  name                   = "default-cato"
  next_hop_in_ip_address = var.floating_ip
  next_hop_type          = "VirtualAppliance"
  resource_group_name    = azurerm_resource_group.azure-rg.name
  route_table_name       = replace(replace("${var.site_name}-viaCato", "-", "_"), " ", "_")
  depends_on = [
    azurerm_route_table.private-rt
  ]
}

resource "azurerm_route_table" "public-rt" {
  bgp_route_propagation_enabled = false
  location                      = var.location
  name                          = replace(replace("${var.site_name}-viaInternet", "-", "_"), " ", "_")
  resource_group_name           = azurerm_resource_group.azure-rg.name
  depends_on = [
    azurerm_resource_group.azure-rg
  ]
}

resource "azurerm_route" "route-internet" {
  address_prefix      = "0.0.0.0/0"
  name                = "default-internet"
  next_hop_type       = "Internet"
  resource_group_name = azurerm_resource_group.azure-rg.name
  route_table_name    = replace(replace("${var.site_name}-viaInternet", "-", "_"), " ", "_")
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
    native_network_range = var.subnet_range_lan
    local_ip             = azurerm_network_interface.lan-nic-primary.private_ip_address
  }
  site_location = var.site_location
  site_type     = var.site_type
}

data "cato_accountSnapshotSite" "azure-site" {
  id = cato_socket_site.azure-site.id
}

locals {
  primary_serial = [for s in data.cato_accountSnapshotSite.azure-site.info.sockets : s.serial if s.is_primary == true]
}

# Create HA user Assigned Identity
resource "azurerm_user_assigned_identity" "CatoHaIdentity" {
  location            = var.location
  name                = "CatoHaIdentity"
  resource_group_name = azurerm_resource_group.azure-rg.name
}

# Create Primary Vsocket Virtual Machine
resource "azurerm_virtual_machine" "vsocket_primary" {
  location                     = var.location
  name                         = "${var.site_name}-vSocket-Primary"
  network_interface_ids        = [azurerm_network_interface.wan-nic-primary.id, azurerm_network_interface.lan-nic-primary.id]
  primary_network_interface_id = azurerm_network_interface.wan-nic-primary.id
  resource_group_name          = azurerm_resource_group.azure-rg.name
  vm_size                      = var.vm_size
  plan {
    name      = "public-cato-socket"
    product   = "cato_socket"
    publisher = "catonetworks"
  }
  boot_diagnostics {
    enabled     = true
    storage_uri = ""
  }
  storage_os_disk {
    create_option   = "Attach"
    name            = "${var.site_name}-vSocket-disk-primary"
    managed_disk_id = azurerm_managed_disk.vSocket_disk_primary.id
    os_type         = "Linux"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.CatoHaIdentity.id]
  }

  depends_on = [
    azurerm_managed_disk.vSocket_disk_primary,
    cato_socket_site.azure-site,
    data.cato_accountSnapshotSite.azure-site
  ]
}

resource "azurerm_managed_disk" "vSocket_disk_primary" {
  name                 = "${var.site_name}-vSocket-disk-primary"
  location             = var.location
  resource_group_name  = azurerm_resource_group.azure-rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "FromImage"
  disk_size_gb         = var.disk_size_gb
  os_type              = "Linux"
  image_reference_id   = var.image_reference_id
  lifecycle {
    ignore_changes = all
  }
}

# To allow mac address to be retrieved
resource "null_resource" "sleep_5_seconds" {
  provisioner "local-exec" {
    command = "sleep 5"
  }
  depends_on = [azurerm_virtual_machine.vsocket_primary]
}

data "azurerm_network_interface" "wannicmac" {
  name                = "${var.site_name}-wanPrimary"
  resource_group_name = azurerm_resource_group.azure-rg.name
  depends_on          = [null_resource.sleep_5_seconds]
}

data "azurerm_network_interface" "lannicmac" {
  name                = "${var.site_name}-lanPrimary"
  resource_group_name = azurerm_resource_group.azure-rg.name
  depends_on          = [null_resource.sleep_5_seconds]
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
  virtual_machine_id         = azurerm_virtual_machine.vsocket_primary.id
  lifecycle {
    ignore_changes = all
  }
  settings = <<SETTINGS
{
  "commandToExecute": "echo '${local.primary_serial[0]}' > /cato/serial.txt; echo '{\"wan_nic\":\"${azurerm_network_interface.wan-nic-primary.name}\",\"wan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.wannicmac.mac_address, "-", ":"))}\",\"wan_nic_ip\":\"${azurerm_network_interface.wan-nic-primary.private_ip_address}\",\"lan_nic\":\"${azurerm_network_interface.lan-nic-primary.name}\",\"lan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.lannicmac.mac_address, "-", ":"))}\",\"lan_nic_ip\":\"${azurerm_network_interface.lan-nic-primary.private_ip_address}\"}' > /cato/nics_config.json; ${join(";", var.commands)}"
}
SETTINGS

  depends_on = [
    azurerm_virtual_machine.vsocket_primary,
    data.azurerm_network_interface.lannicmac,
    data.azurerm_network_interface.wannicmac
  ]
}

# To allow socket to upgrade, so secondary socket can be added
resource "null_resource" "sleep_300_seconds" {
  provisioner "local-exec" {
    command = "sleep 300"
  }
  depends_on = [azurerm_virtual_machine_extension.vsocket-custom-script-primary]
}

#################################################################################
# Add secondary socket to site via API until socket_site resource is updated to natively support
resource "null_resource" "configure_secondary_azure_vsocket" {
  depends_on = [null_resource.sleep_300_seconds]

  provisioner "local-exec" {
    command = <<EOF
      response=$(curl -k -X POST \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "x-API-Key: ${var.token}" \
        "${var.baseurl}" \
        --data '{
          "query": "mutation siteAddSecondaryAzureVSocket($accountId: ID!, $addSecondaryAzureVSocketInput: AddSecondaryAzureVSocketInput!) { site(accountId: $accountId) { addSecondaryAzureVSocket(input: $addSecondaryAzureVSocketInput) { id } } }",
          "variables": {
            "accountId": "${var.account_id}",
            "addSecondaryAzureVSocketInput": {
              "floatingIp": "${var.floating_ip}",
              "interfaceIp": "${azurerm_network_interface.lan-nic-secondary.private_ip_address}",
              "site": {
                "by": "ID",
                "input": "${cato_socket_site.azure-site.id}"
              }
            }
          },
          "operationName": "siteAddSecondaryAzureVSocket"
        }' )
    EOF
  }

  triggers = {
    account_id = var.account_id
    site_id    = cato_socket_site.azure-site.id
  }
}

# Sleep to allow Secondary vSocket serial retrieval
resource "null_resource" "sleep_30_seconds" {
  provisioner "local-exec" {
    command = "sleep 30"
  }
  depends_on = [null_resource.configure_secondary_azure_vsocket]
}

# Create Secondary Vsocket Virtual Machine
data "cato_accountSnapshotSite" "azure-site-secondary" {
  depends_on = [null_resource.sleep_30_seconds]
  id         = cato_socket_site.azure-site.id
}

locals {
  secondary_serial = [for s in data.cato_accountSnapshotSite.azure-site-secondary.info.sockets : s.serial if s.is_primary == false]
}

resource "azurerm_virtual_machine" "vsocket_secondary" {
  location                     = var.location
  name                         = "${var.site_name}-vSocket-Secondary"
  network_interface_ids        = [azurerm_network_interface.wan-nic-secondary.id, azurerm_network_interface.lan-nic-secondary.id]
  primary_network_interface_id = azurerm_network_interface.wan-nic-secondary.id
  resource_group_name          = azurerm_resource_group.azure-rg.name
  vm_size                      = var.vm_size
  plan {
    name      = "public-cato-socket"
    product   = "cato_socket"
    publisher = "catonetworks"
  }
  boot_diagnostics {
    enabled     = true
    storage_uri = ""
  }
  storage_os_disk {
    create_option   = "Attach"
    name            = "${var.site_name}-vSocket-disk-secondary"
    managed_disk_id = azurerm_managed_disk.vSocket_disk_secondary.id
    os_type         = "Linux"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.CatoHaIdentity.id]
  }

  depends_on = [
    azurerm_managed_disk.vSocket_disk_secondary,
    data.cato_accountSnapshotSite.azure-site-secondary,
    null_resource.configure_secondary_azure_vsocket
  ]
}

resource "azurerm_managed_disk" "vSocket_disk_secondary" {
  depends_on           = [data.cato_accountSnapshotSite.azure-site-secondary]
  name                 = "${var.site_name}-vSocket-disk-secondary"
  location             = var.location
  resource_group_name  = azurerm_resource_group.azure-rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "FromImage"
  disk_size_gb         = var.disk_size_gb
  os_type              = "Linux"
  image_reference_id   = var.image_reference_id
  lifecycle {
    ignore_changes = all
  }
}

#Sleep to allow Secondary vSocket interface mac address retrieval
resource "null_resource" "sleep_5_seconds-2" {
  provisioner "local-exec" {
    command = "sleep 5"
  }
  depends_on = [azurerm_virtual_machine.vsocket_secondary]
}

data "azurerm_network_interface" "wannicmac-2" {
  name                = "${var.site_name}-wanSecondary"
  resource_group_name = azurerm_resource_group.azure-rg.name
  depends_on          = [null_resource.sleep_5_seconds-2]
}

data "azurerm_network_interface" "lannicmac-2" {
  name                = "${var.site_name}-lanSecondary"
  resource_group_name = azurerm_resource_group.azure-rg.name
  depends_on          = [null_resource.sleep_5_seconds-2]
}

variable "commands-secondary" {
  type = list(string)
  default = [
    "rm /cato/deviceid.txt",
    "rm /cato/socket/configuration/socket_registration.json",
    "nohup /cato/socket/run_socket_daemon.sh &"
  ]
}

resource "azurerm_virtual_machine_extension" "vsocket-custom-script-secondary" {
  auto_upgrade_minor_version = true
  name                       = "vsocket-custom-script-secondary"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  virtual_machine_id         = azurerm_virtual_machine.vsocket_secondary.id
  lifecycle {
    ignore_changes = all
  }
  settings = <<SETTINGS
 {
  "commandToExecute": "echo '${local.secondary_serial[0]}' > /cato/serial.txt; echo '{\"wan_nic\":\"${azurerm_network_interface.wan-nic-secondary.name}\",\"wan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.wannicmac-2.mac_address, "-", ":"))}\",\"wan_nic_ip\":\"${azurerm_network_interface.wan-nic-secondary.private_ip_address}\",\"lan_nic\":\"${azurerm_network_interface.lan-nic-secondary.name}\",\"lan_nic_mac\":\"${lower(replace(data.azurerm_network_interface.lannicmac-2.mac_address, "-", ":"))}\",\"lan_nic_ip\":\"${azurerm_network_interface.lan-nic-secondary.private_ip_address}\"}' > /cato/nics_config.json; ${join(";", var.commands)}"
 }
SETTINGS
  depends_on = [
    azurerm_virtual_machine.vsocket_secondary
  ]
}

# Create HA Settings Secondary
resource "null_resource" "run_command_ha_primary" {
  provisioner "local-exec" {
    command = <<EOT
      az vm run-command invoke \
        --resource-group ${azurerm_resource_group.azure-rg.name} \
        --name "${var.site_name}-vSocket-Primary" \
        --command-id RunShellScript \
        --scripts "echo '{\"location\": \"${var.location}\", \"subscription_id\": \"${var.azure_subscription_id}\", \"vnet\": \"${azurerm_virtual_network.vnet.name}\", \"group\": \"${azurerm_resource_group.azure-rg.name}\", \"vnet_group\": \"${azurerm_resource_group.azure-rg.name}\", \"subnet\": \"${azurerm_subnet.subnet-lan.name}\", \"nic\": \"${azurerm_network_interface.lan-nic-primary.name}\", \"ha_nic\": \"${azurerm_network_interface.lan-nic-secondary.name}\", \"lan_nic_ip\": \"${azurerm_network_interface.lan-nic-primary.private_ip_address}\", \"lan_nic_mac\": \"${azurerm_network_interface.lan-nic-primary.mac_address}\", \"subnet_cidr\": \"${var.subnet_range_lan}\", \"az_mgmt_url\": \"management.azure.com\"}' > /cato/socket/configuration/vm_config.json"
    EOT
  }

  depends_on = [
    azurerm_virtual_machine_extension.vsocket-custom-script-secondary
  ]
}

resource "null_resource" "run_command_ha_secondary" {
  provisioner "local-exec" {
    command = <<EOT
      az vm run-command invoke \
        --resource-group ${azurerm_resource_group.azure-rg.name} \
        --name "${var.site_name}-vSocket-Secondary" \
        --command-id RunShellScript \
        --scripts "echo '{\"location\": \"${var.location}\", \"subscription_id\": \"${var.azure_subscription_id}\", \"vnet\": \"${azurerm_virtual_network.vnet.name}\", \"group\": \"${azurerm_resource_group.azure-rg.name}\", \"vnet_group\": \"${azurerm_resource_group.azure-rg.name}\", \"subnet\": \"${azurerm_subnet.subnet-lan.name}\", \"nic\": \"${azurerm_network_interface.lan-nic-secondary.name}\", \"ha_nic\": \"${azurerm_network_interface.lan-nic-primary.name}\", \"lan_nic_ip\": \"${azurerm_network_interface.lan-nic-secondary.private_ip_address}\", \"lan_nic_mac\": \"${azurerm_network_interface.lan-nic-secondary.mac_address}\", \"subnet_cidr\": \"${var.subnet_range_lan}\", \"az_mgmt_url\": \"management.azure.com\"}' > /cato/socket/configuration/vm_config.json"
    EOT
  }

  depends_on = [
    azurerm_virtual_machine_extension.vsocket-custom-script-secondary
  ]
}

#Output MAC addess of Secondary LAN interface
output "lan-sec-mac" {
  value = azurerm_network_interface.lan-nic-secondary.mac_address
}

# Role assignments for secondary lan nic and subnet
resource "azurerm_role_assignment" "secondary_nic_ha_role" {
  principal_id         = azurerm_user_assigned_identity.CatoHaIdentity.principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope                = azurerm_network_interface.lan-nic-secondary.id
  depends_on           = [azurerm_virtual_machine.vsocket_secondary]
}

resource "azurerm_role_assignment" "lan-subnet-role" {
  principal_id         = azurerm_user_assigned_identity.CatoHaIdentity.principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope                = "/subscriptions/${var.azure_subscription_id}/resourcegroups/${azurerm_resource_group.azure-rg.name}/providers/Microsoft.Network/virtualNetworks/${azurerm_virtual_network.vnet.name}/subnets/${azurerm_subnet.subnet-lan.name}"
  depends_on           = [azurerm_user_assigned_identity.CatoHaIdentity]
}

#Temporary role assignments for primary
resource "azurerm_role_assignment" "primary_nic_ha_role" {
  principal_id         = azurerm_user_assigned_identity.CatoHaIdentity.principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope                = "/subscriptions/${var.azure_subscription_id}/resourcegroups/${azurerm_resource_group.azure-rg.name}/providers/Microsoft.Network/networkInterfaces/${azurerm_network_interface.lan-nic-primary.name}"
  depends_on           = [azurerm_user_assigned_identity.CatoHaIdentity]
}

# Time delay to allow for vsockets to upgrade
resource "null_resource" "delay" {
  depends_on = [null_resource.run_command_ha_secondary]
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

# Reboot both vsockets
resource "null_resource" "reboot_vsocket_primary" {
  provisioner "local-exec" {
    command = <<EOT
      az vm restart --resource-group "${azurerm_resource_group.azure-rg.name}" --name "${var.site_name}-vSocket-Primary"
    EOT
  }

  depends_on = [
    null_resource.run_command_ha_secondary
  ]
}

resource "null_resource" "reboot_vsocket_secondary" {
  provisioner "local-exec" {
    command = <<EOT
      az vm restart --resource-group "${azurerm_resource_group.azure-rg.name}" --name "${var.site_name}-vSocket-Secondary"
    EOT
  }

  depends_on = [
    null_resource.run_command_ha_secondary
  ]
}

# Time delay to allow for vsockets HA to complete configuration
resource "null_resource" "delay-ha" {
  depends_on = [null_resource.reboot_vsocket_secondary]
  provisioner "local-exec" {
    command = "sleep 75"
  }
}

# Cato license resource
resource "cato_license" "license" {
  depends_on = [null_resource.reboot_vsocket_secondary]
  count      = var.license_id == null ? 0 : 1
  site_id    = cato_socket_site.azure-site.id
  license_id = var.license_id
  bw         = var.license_bw == null ? null : var.license_bw
}
