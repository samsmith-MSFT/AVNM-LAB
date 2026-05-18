subscription_id = "<subID>"
resource_group_name = "<rgName>"
location = "<location>"
vnet_name_hub           = "vnet-avnm-hub"
vnet_name_spokes        = ["vnet-avnm-spoke1", "vnet-avnm-spoke2", "vnet-avnm-spoke3"]

# AVNM and IPAM Pool Configuration
avnm_name = "avnm-hub-spoke"
ipam_pool_address_prefix = "10.0.0.0/14"
hub_vnet_ip_count = "65536"        # Allocates /16 hub VNet (65536 IPs)
vnet_ip_count = "256"              # Allocates /24 spoke VNets (256 IPs each)
firewall_subnet_ip_count = "256"   # Allocates /24 firewall subnet (256 IPs)
subnet_ip_count = "32"             # Allocates /27 spoke subnets (32 IPs each)
