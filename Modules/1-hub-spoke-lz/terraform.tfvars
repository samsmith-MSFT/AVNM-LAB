subscription_id = "<subID>"
resource_group_name = "<rgName>"
location = "<location>"
vnet_name_hub           = "vnet-avnm-hub"
vnet_name_spokes        = ["vnet-avnm-spoke1", "vnet-avnm-spoke2", "vnet-avnm-spoke3"]
address_space_hub       = ["10.1.0.0/16"]
subnet_space_fw        = ["10.1.1.0/24"]

# AVNM and IPAM Pool Configuration
avnm_name = "avnm-hub-spoke"
ipam_pool_address_prefix = "10.0.0.0/14"
subnet_ip_count = "32"   # Allocates /27 subnets (32 IPs each)
vnet_ip_count = "256"    # Allocates /24 VNets (256 IPs each)
