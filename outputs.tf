## The following attributes are exported:
output "resource_group_name" {
  description = "The name of the Azure Resource Group used for deployment."
  value       = azurerm_resource_group.azure-rg.name
}

output "wan_nic_name_primary" {
  description = "The name of the primary WAN network interface."
  value       = azurerm_network_interface.wan-nic-primary.name
}

output "lan_nic_name_primary" {
  description = "The name of the primary LAN network interface."
  value       = azurerm_network_interface.lan-nic-primary.name
}

output "wan_nic_name_secondary" {
  description = "The name of the secondary WAN network interface for HA."
  value       = azurerm_network_interface.wan-nic-secondary.name
}

output "lan_nic_name_secondary" {
  description = "The name of the secondary LAN network interface for HA."
  value       = azurerm_network_interface.lan-nic-secondary.name
}

output "lan_subnet_id" {
  description = "The ID of the LAN subnet within the virtual network."
  value       = azurerm_subnet.subnet-lan.id
}

output "vnet_name" {
  description = "The name of the Azure Virtual Network used by the deployment."
  value       = azurerm_virtual_network.vnet.name
}

output "lan_subnet_name" {
  description = "The name of the LAN subnet within the virtual network."
  value       = azurerm_subnet.subnet-lan.name
}

# Cato Socket Site Outputs
output "cato_site_id" {
  description = "ID of the Cato Socket Site"
  value       = cato_socket_site.azure-site.id
}

output "cato_site_name" {
  description = "Name of the Cato Site"
  value       = cato_socket_site.azure-site.name
}

output "cato_primary_serial" {
  description = "Primary Cato Socket Serial Number"
  value       = try(local.primary_serial[0], "N/A")
}

output "cato_secondary_serial" {
  description = "Secondary Cato Socket Serial Number"
  value       = try(local.secondary_serial[0], "N/A")
}

# Network Interfaces Outputs
output "wan_primary_nic_id" {
  description = "ID of the WAN Primary Network Interface"
  value       = azurerm_network_interface.wan-nic-primary.id
}

output "lan_primary_nic_id" {
  description = "ID of the LAN Primary Network Interface"
  value       = azurerm_network_interface.lan-nic-primary.id
}

output "lan_primary_nic_mac_address" {
  description = "MAC of the LAN Primary Network Interface"
  value       = azurerm_network_interface.lan-nic-primary
}

output "wan_primary_nic_mac_address" {
  description = "MAC of the LAN Primary Network Interface"
  value       = azurerm_network_interface.wan-nic-primary
}

output "wan_secondary_nic_id" {
  description = "ID of the WAN Secondary Network Interface"
  value       = azurerm_network_interface.wan-nic-secondary.id
}

output "lan_secondary_nic_id" {
  description = "ID of the LAN Secondary Network Interface"
  value       = azurerm_network_interface.lan-nic-secondary.id
}

# Virtual Machine Outputs
output "vsocket_primary_vm_id" {
  description = "ID of the Primary vSocket Virtual Machine"
  value       = azurerm_virtual_machine.vsocket_primary.id
}

output "vsocket_primary_vm_name" {
  description = "Name of the Primary vSocket Virtual Machine"
  value       = azurerm_virtual_machine.vsocket_primary.name
}

output "lan_secondary_nic_mac_address" {
  description = "MAC of the LAN Secondary Network Interface"
  value       = azurerm_network_interface.lan-nic-secondary
}

output "wan_secondary_nic_mac_address" {
  description = "MAC of the LAN Secondary Network Interface"
  value       = azurerm_network_interface.wan-nic-secondary
}

output "vsocket_secondary_vm_id" {
  description = "ID of the Secondary vSocket Virtual Machine"
  value       = azurerm_virtual_machine.vsocket_secondary.id
}

output "vsocket_secondary_vm_name" {
  description = "Name of the Secondary vSocket Virtual Machine"
  value       = azurerm_virtual_machine.vsocket_secondary.name
}

# Managed Disks Outputs
output "primary_disk_id" {
  description = "ID of the Primary vSocket Managed Disk"
  value       = azurerm_managed_disk.vSocket_disk_primary.id
}

output "primary_disk_name" {
  description = "Name of the Primary vSocket Managed Disk"
  value       = azurerm_managed_disk.vSocket_disk_primary.name
}

output "secondary_disk_id" {
  description = "ID of the Secondary vSocket Managed Disk"
  value       = azurerm_managed_disk.vSocket_disk_secondary.id
}

output "secondary_disk_name" {
  description = "Name of the Secondary vSocket Managed Disk"
  value       = azurerm_managed_disk.vSocket_disk_secondary.name
}

# User Assigned Identity
output "ha_identity_id" {
  description = "ID of the User Assigned Identity for HA"
  value       = azurerm_user_assigned_identity.CatoHaIdentity.id
}

output "ha_identity_principal_id" {
  description = "Principal ID of the HA Identity"
  value       = azurerm_user_assigned_identity.CatoHaIdentity.principal_id
}

# Role Assignments Outputs
output "primary_nic_role_assignment_id" {
  description = "Role Assignment ID for the Primary NIC"
  value       = azurerm_role_assignment.primary_nic_ha_role.id
}

output "secondary_nic_role_assignment_id" {
  description = "Role Assignment ID for the Secondary NIC"
  value       = azurerm_role_assignment.secondary_nic_ha_role.id
}

output "lan_subnet_role_assignment_id" {
  description = "Role Assignment ID for the LAN Subnet"
  value       = azurerm_role_assignment.lan-subnet-role.id
}

# LAN MAC Address Output
output "lan_secondary_mac_address" {
  description = "MAC Address of the Secondary LAN Interface"
  value       = azurerm_network_interface.lan-nic-secondary.mac_address
}

# Reboot Status Outputs
output "vsocket_primary_reboot_status" {
  description = "Status of the Primary vSocket VM Reboot"
  value       = "Reboot triggered via Terraform"
  depends_on  = [null_resource.reboot_vsocket_primary]
}

output "vsocket_secondary_reboot_status" {
  description = "Status of the Secondary vSocket VM Reboot"
  value       = "Reboot triggered via Terraform"
  depends_on  = [null_resource.reboot_vsocket_secondary]
}

output "cato_license_site" {
  value = var.license_id == null ? null : {
    id           = cato_license.license[0].id
    license_id   = cato_license.license[0].license_id
    license_info = cato_license.license[0].license_info
    site_id      = cato_license.license[0].site_id
  }
}