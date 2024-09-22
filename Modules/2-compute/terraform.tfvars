subscription_id = "<subID>"
location = "<location>"
resource_group_name = "<rgName>"
vnet_name_spokes        = ["vnet-avnm-spoke1", "vnet-avnm-spoke2", "vnet-avnm-spoke3"]
subnet_space_spokes     = {
  "vnet-avnm-spoke1" = ["10.2.0.0/27"],
  "vnet-avnm-spoke2" = ["10.3.0.0/27"],
  "vnet-avnm-spoke3" = ["10.4.0.0/27"]
}
