
## Cato Provider Variables
variable "token" {
  description = "API token used to authenticate with the Cato Networks API."
  sensitive = true
}

variable "account_id" {
  description = "Account ID used for the Cato Networks integration."
  type        = number
  default     = null
}

variable "baseurl" {
  description = "Base URL for the Cato Networks API."
  type        = string
  default     = "https://api.catonetworks.com/api/v1/graphql2"
}

variable "site_name" {
  description = "Name of the vsocket site"
  type        = string
}

variable "site_description" {
  description = "Description of the vsocket site"
  type        = string
}

variable "site_type" {
  description = "The type of the site"
  type        = string
  default     = "CLOUD_DC"
  validation {
    condition     = contains(["DATACENTER", "BRANCH", "CLOUD_DC", "HEADQUARTERS"], var.site_type)
    error_message = "The site_type variable must be one of 'DATACENTER','BRANCH','CLOUD_DC','HEADQUARTERS'."
  }
}

variable "site_location" {
  type = object({
    city         = string
    country_code = string
    state_code   = string
    timezone     = string
  })
}


## VNET Variables
variable "create_resource_group" {
  description = "Resource group creation true will create and false will use exsiting"
  type        = bool
}
variable "resource_group_name" {
  description = "Resource group name required if you want to deploy into existing Resource group"
  type        = string
}

variable "vnet_id" {
  description = "VNET ID required if you want to deploy into existing VNET"
  type        = string
  default     = null
}

variable "vnet_name" {
  description = "VNET Name required if you want to deploy into existing VNET"
  type        = string
}

variable "azure_subscription_id" {
  description = "The Azure Subscription ID where the resources will be created. Example: 00000000-0000-0000-0000-000000000000"
  type        = string
  sensitive = true
}

variable "location" {
  type    = string
  default = null
}

variable "lan_ip_primary" {
  type        = string
  description = "Local IP Address of socket LAN interface"
  default     = null
}

variable "lan_ip_secondary" {
  type        = string
  description = "Local IP Address of socket LAN interface"
  default     = null
}

variable "floating_ip" {
  type        = string
  description = "Floating IP Address for the vSocket"
  default     = null
}

variable "dns_servers" {
  type = list(string)
  default = [
    "168.63.129.16", # Azure DNS
    "10.254.254.1",  # Cato Cloud DNS
    "1.1.1.1",
    "8.8.8.8"
  ]
}

variable "subnet_range_wan" {
  type        = string
  description = <<EOT
    Choose a range within the VPC to use as the Public/WAN subnet. This subnet will be used to access the public internet and securely tunnel to the Cato Cloud.
    The minimum subnet length to support High Availability is /28.
    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X
	EOT
  default     = null
}

variable "subnet_range_lan" {
  type        = string
  description = <<EOT
    Choose a range within the VPC to use as the Private/LAN subnet. This subnet will host the target LAN interface of the vSocket so resources in the VPC (or AWS Region) can route to the Cato Cloud.
    The minimum subnet length to support High Availability is /29.
    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X
	EOT
  default     = null
}


variable "vnet_prefix" {
  type        = string
  description = <<EOT
  	Choose a unique range for your new VPC that does not conflict with the rest of your Wide Area Network.
    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X
	EOT
  default     = null
}

variable "routed_ranges" {
  description = "Routed ranges to be accessed behind the vSocket site"
  type        = list(string)
  default     = null
}

variable "routed_ranges_names" {
  description = "Routed ranges names"
  type        = list(string)
  default     = null
}

variable "routed_ranges_gateway" {
  description = "Routed ranges gateway"
  type        = string
  default     = null
}

variable "vm_size" {
  description = "(Required) Specifies the size of the Virtual Machine. See Azure VM Naming Conventions: https://learn.microsoft.com/en-us/azure/virtual-machines/vm-naming-conventions"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "disk_size_gb" {
  description = "Size of the managed disk in GB."
  type        = number
  default     = 8
  validation {
    condition     = var.disk_size_gb > 0
    error_message = "Disk size must be greater than 0."
  }
}

variable "image_reference_id" {
  description = "The path to the image used to deploy a specific version of the virtual socket."
  type        = string
  default     = "/Subscriptions/38b5ec1d-b3b6-4f50-a34e-f04a67121955/Providers/Microsoft.Compute/Locations/eastus/Publishers/catonetworks/ArtifactTypes/VMImage/Offers/cato_socket/Skus/public-cato-socket/Versions/21.0.18517"
}

## Socket interface settings
variable "upstream_bandwidth" {
  description = "Sockets upstream interface WAN Bandwidth in Mbps"
  type = string
  default = "null"
}

variable "downstream_bandwidth" {
  description = "Sockets downstream interface WAN Bandwidth in Mbps"
  type = string
  default = "null"
}

# Avalability Zones and sets
variable "availability_set_id" {
  description = "Availability set ID"
  type = string
  default = null
}

variable "vsocket_primary_zone" {
  description = "Primary vsocket Availability Zone"
  type = string
  default = null
}

variable "vsocket_secondary_zone" {
  description = "Secondary vsocket Availability Zone"
  type = string
  default = null
}

variable "license_id" {
  description = "The license ID for the Cato vSocket of license type CATO_SITE, CATO_SSE_SITE, CATO_PB, CATO_PB_SSE.  Example License ID value: 'abcde123-abcd-1234-abcd-abcde1234567'.  Note that licenses are for commercial accounts, and not supported for trial accounts."
  type        = string
  default     = null
}

variable "license_bw" {
  description = "The license bandwidth number for the cato site, specifying bandwidth ONLY applies for pooled licenses.  For a standard site license that is not pooled, leave this value null. Must be a number greater than 0 and an increment of 10."
  type        = string
  default     = null
}
