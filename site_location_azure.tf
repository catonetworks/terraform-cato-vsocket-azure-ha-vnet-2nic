
data "cato_siteLocation" "site_location" {
  filters = concat([
    {
      field     = "city"
      operation = "exact"
      search    = local.region_to_location[local.locationstr].city
    },
    {
      field     = "country_name"
      operation = "exact"
      search    = local.region_to_location[local.locationstr].country
    }
    ],
    # Conditionally add state filter only if state exists
    local.region_to_location[local.locationstr].state != null ? [
      {
        field     = "state_name"
        operation = "exact"
        search    = local.region_to_location[local.locationstr].state
      }
  ] : [])
}

locals {
  cur_site_location = var.site_location != null ? var.site_location : data.cato_siteLocation.site_location[0]
  locationstr       = lower(replace(var.location, " ", ""))
  # Manual mapping of Azure regions to their cities and countries
  # Since Azure doesn't provide city/country in the API, we create our own mapping
  region_to_location = {
    # North America - United States
    "eastus"         = { city = "Ashburn", state = "Virginia", country = "United States", continent = "North America", timezone = "UTC-5" }
    "eastus2"        = { city = "Ashburn", state = "Virginia", country = "United States", continent = "North America", timezone = "UTC-5" }
    "centralus"      = { city = "Des Moines", state = "Iowa", country = "United States", continent = "North America", timezone = "UTC-6" }
    "northcentralus" = { city = "Chicago", state = "Illinois", country = "United States", continent = "North America", timezone = "UTC-6" }
    "southcentralus" = { city = "San Antonio", state = "Texas", country = "United States", continent = "North America", timezone = "UTC-6" }
    "westcentralus"  = { city = "Cheyenne", state = "Wyoming", country = "United States", continent = "North America", timezone = "UTC-7" }
    "westus"         = { city = "San Francisco", state = "California", country = "United States", continent = "North America", timezone = "UTC-8" }
    "westus2"        = { city = "Seattle", state = "Washington", country = "United States", continent = "North America", timezone = "UTC-8" }
    "westus3"        = { city = "Phoenix", state = "Arizona", country = "United States", continent = "North America", timezone = "UTC-7" }

    # North America - Canada
    "canadacentral" = { city = "Toronto", state = null, country = "Canada", continent = "North America", timezone = "UTC-5" }
    "canadaeast"    = { city = "Montréal", state = null, country = "Canada", continent = "North America", timezone = "UTC-5" }

    # Europe - Countries without states/provinces use null
    "northeurope"        = { city = "Dublin", state = null, country = "Ireland", continent = "Europe", timezone = "UTC+0" }
    "westeurope"         = { city = "Amsterdam", state = null, country = "Netherlands", continent = "Europe", timezone = "UTC+1" }
    "francecentral"      = { city = "Paris", state = null, country = "France", continent = "Europe", timezone = "UTC+1" }
    "francesouth"        = { city = "Marseille", state = null, country = "France", continent = "Europe", timezone = "UTC+1" }
    "germanywestcentral" = { city = "Frankfurt (Oder)", state = null, country = "Germany", continent = "Europe", timezone = "UTC+1" }
    "germanynorth"       = { city = "Berlin", state = null, country = "Germany", continent = "Europe", timezone = "UTC+1" }
    "norwayeast"         = { city = "Oslo", state = null, country = "Norway", continent = "Europe", timezone = "UTC+1" }
    "norwaywest"         = { city = "Stavanger", state = null, country = "Norway", continent = "Europe", timezone = "UTC+1" }
    "swedencentral"      = { city = "Gävle", state = null, country = "Sweden", continent = "Europe", timezone = "UTC+1" }
    "switzerlandnorth"   = { city = "Zürich", state = null, country = "Switzerland", continent = "Europe", timezone = "UTC+1" }
    "switzerlandwest"    = { city = "Genève", state = null, country = "Switzerland", continent = "Europe", timezone = "UTC+1" }
    "uksouth"            = { city = "London", state = null, country = "United Kingdom", continent = "Europe", timezone = "UTC+0" }
    "ukwest"             = { city = "Cardiff", state = null, country = "United Kingdom", continent = "Europe", timezone = "UTC+0" }

    # Asia Pacific
    "eastasia"        = { city = "Hong Kong", state = null, country = "Hong Kong", continent = "Asia Pacific", timezone = "UTC+8" }
    "southeastasia"   = { city = "Singapore", state = null, country = "Singapore", continent = "Asia Pacific", timezone = "UTC+8" }
    "centralindia"    = { city = "Pune", state = "Maharashtra", country = "India", continent = "Asia Pacific", timezone = "UTC+5:30" }
    "southindia"      = { city = "Chennai", state = "Tamil Nadu", country = "India", continent = "Asia Pacific", timezone = "UTC+5:30" }
    "westindia"       = { city = "Mumbai", state = "Maharashtra", country = "India", continent = "Asia Pacific", timezone = "UTC+5:30" }
    "jioindiacentral" = { city = "Jamnagar", state = "Gujarat", country = "India", continent = "Asia Pacific", timezone = "UTC+5:30" }
    "jioindiawest"    = { city = "Jamnagar", state = "Gujarat", country = "India", continent = "Asia Pacific", timezone = "UTC+5:30" }
    "japaneast"       = { city = "Tokyo", state = null, country = "Japan", continent = "Asia Pacific", timezone = "UTC+9" }
    "japanwest"       = { city = "Osaka", state = null, country = "Japan", continent = "Asia Pacific", timezone = "UTC+9" }
    "koreacentral"    = { city = "Seoul", state = null, country = "South Korea", continent = "Asia Pacific", timezone = "UTC+9" }
    "koreasouth"      = { city = "Busan", state = null, country = "South Korea", continent = "Asia Pacific", timezone = "UTC+9" }

    # Asia Pacific - Australia
    "australiaeast"      = { city = "Sydney", state = "New South Wales", country = "Australia", continent = "Asia Pacific", timezone = "UTC+10" }
    "australiacentral"   = { city = "Canberra", state = "Australian Capital Territory", country = "Australia", continent = "Asia Pacific", timezone = "UTC+10" }
    "australiacentral2"  = { city = "Canberra", state = "Australian Capital Territory", country = "Australia", continent = "Asia Pacific", timezone = "UTC+10" }
    "australiasoutheast" = { city = "Melbourne", state = "Victoria", country = "Australia", continent = "Asia Pacific", timezone = "UTC+10" }

    # Middle East
    "uaenorth"     = { city = "Dubai", state = null, country = "United Arab Emirates", continent = "Middle East", timezone = "UTC+4" }
    "uaecentral"   = { city = "Abu Dhabi", state = null, country = "United Arab Emirates", continent = "Middle East", timezone = "UTC+4" }
    "qatarcentral" = { city = "Doha", state = null, country = "Qatar", continent = "Middle East", timezone = "UTC+3" }

    # Africa
    "southafricanorth" = { city = "Johannesburg", state = null, country = "South Africa", continent = "Africa", timezone = "UTC+2" }
    "southafricawest"  = { city = "Cape Town", state = null, country = "South Africa", continent = "Africa", timezone = "UTC+2" }

    # South America
    "brazilsouth" = { city = "São Paulo", state = "São Paulo", country = "Brazil", continent = "South America", timezone = "UTC-3" }
  }
}

output "site_location" {
  value = data.cato_siteLocation.site_location
}
