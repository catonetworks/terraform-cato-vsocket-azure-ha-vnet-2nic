## 0.0.1 (2025-05-10)

### Features
- Initial commit with 2 nic Azure vsockets HA with VNET

## 0.0.2 (2025-05-10)

### Features
- Addition of delay timer to allow HA configuration to complete

## 0.0.3 (2025-05-10)

### Features
- Updated README.md

## 0.0.4 (2025-06-11)

### Features
- Updated README.md
- Added optional variable to configure sockets Bandwidth
- Added optional variable to configure sockets Routed Networks and Names
- Added optional variable for use of existing Resource Group
- Added optional variable for use of existing VNET
- Fixed error on Cato site deletion

## 0.0.5 (2025-06-11)

### Features
- Updated README.md with further instructions for module use

## 0.0.6 (2025-06-14)

### Features
- Updated README.md with new optional configuration
- Updated null_resources to terraform_data
- Added optional variable to configure custom gateway for routed ranges
- Added optional variable to configure avalability zones and sets

## 0.0.7 (2025-06-14)

### Features
- Updated README.md with new optional configuration
- Updated null_resources to terraform_data
- Added optional variable to configure custom gateway for routed ranges
- Added optional variable to configure avalability zones and sets

## 0.1.0 (2025-06-25)

### Features
- **VM Customization**: Introduced variables (`vm_os_disk_config`, `vm_image_config`, `enable_boot_diagnostics`) for greater control over the primary VM's OS disk, marketplace image, and boot diagnostics.
- **Resource Tagging**: Added a `tags` variable to apply custom tags to all created Azure resources for improved organization and cost tracking.
- **Automatic Site Location**: Added logic to automatically determine the Cato Site Location based on the specified Azure region, simplifying setup. Manual override is available.
- **Enhanced Network Configuration**: The `routed_networks` variable now uses a `map(string)` for a more stable and predictable configuration of routed ranges.
- **New Outputs**: Added comprehensive outputs for resource IDs, names, and properties (e.g., VM IDs, NIC details, Cato site info).

### Changed
- **Major Code Refactoring**: The module has been significantly refactored for improved readability, maintainability, and robustness.
  - Code is now split into logical files (`variables.tf`, `locals.tf`, `outputs.tf`, etc.).
  - Replaced the deprecated `azurerm_virtual_machine` resource with `azurerm_linux_virtual_machine`.
  - Switched to the `templatefile()` function for generating inline scripts, making them easier to manage.
  - Resource naming is now more consistent and dynamic (e.g., User-Assigned Identity).
- **Variable Enhancements**:
  - Enforced strict type constraints on all variables.
  - Marked sensitive variables like `token` and `azure_subscription_id` as `sensitive`.
- **Dependency Management**: Pinned provider versions in `versions.tf` to ensure repeatable deployments.

### Removed
- **Simplified VNet Input**: Removed the need to provide a VNet ID directly. The module now handles this logic internally.

## 0.1.1 (2025-07-07)

### Features
- **Naming Customization**: Introduced variables (`resource_prefix_name`, `vsocket_primary_name`, `vsocket_secondary_name`,`wan_subnet_name`,`lan_subnet_name`, `ha_identity_name`, `vsocket_primary_disk_name`, `vsocket_secondary_disk_name` ) for greater customisation of resource naming.
- **Availability Zones**: Added option to configure Availability Zones.

## 0.1.2 

### Features 
 - Update SiteLocation (v0.0.2)
 - Version lock Cato provider to 0.0.30 or greater

 ## 0.1.3 

 ## Features 
 - fix Malformed siteLocation.tf

 ## 0.1.4

 ### Features 
 - fix resource-prefix-name variable to make nullable 
 - add additional logic for resource naming 
 - Update Sitelocation with Poland 
 - Update SiteLocation with Zurich Fix
 - Update Routed-Networks to Support SRT and NAT Range
 - Update Documentation (Notes) to describe Static Range Translation Requirements

## 0.1.5

### Features
 - Updated to use latest provider version 
  - Adjusted routed_networks call to include interface_index 
 - Version Lock to Provider version 0.0.38 or greater

## 0.1.6

### Features
 - Update Documentation

 ## 0.1.7

 ### Features 
  - Added additional naming options
    - lan_nic_primary_name
    - lan_nic_secondary_name
    - lan_nic_primary_ipconfig_name
    - lan_nic_secondary_ipconfig_name
    - wan_nic_primary_name
    - wan_nic_secondary_name
    - wan_nic_primary_ipconfig_name
    - wan_nic_secondary_ipconfig_name
  - Added additional example within README.md
  - Updated API Calls to export additional debug information
  - Updated CLI Calls to export additional debug information
  - Updated Required Terraform Version to 1.5
  - Removed Sensitive flag for Azure Subscription ID