# 🌐 Azure Virtual Network Manager (AVNM) Lab with IP Address Management

[![Terraform](https://img.shields.io/badge/Terraform-1.x-blue.svg)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-blue.svg)](https://azure.microsoft.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A comprehensive Terraform lab environment that demonstrates **Azure Virtual Network Manager (AVNM)** with advanced **IP Address Management (IPAM)** capabilities. This lab showcases modern cloud networking patterns including hub-spoke topology, dynamic subnet allocation, and centralized network management.

## 🏗️ **Architecture Overview**

This lab deploys a simplified **2-module architecture** that creates a complete hub-spoke network topology with automatic IP address management:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Spoke VNet 1  │    │   Hub VNet      │    │   Spoke VNet 2  │
│  (Dynamic IPs)  │◄──►│  Azure Firewall │◄──►│  (Dynamic IPs)  │
│                 │    │  10.1.0.0/16    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                       ┌─────────────────┐
                       │   Spoke VNet 3  │
                       │  (Dynamic IPs)  │
                       └─────────────────┘
```

### **🎯 Key Features**

- ✅ **Hub-Spoke Topology** with Azure Virtual Network Manager
- ✅ **Dynamic IP Allocation** from centralized IPAM pool (`10.1.0.0/14`)
- ✅ **Automatic Subnet Management** - no manual IP planning required
- ✅ **Azure Firewall** with routing and security rules
- ✅ **Network Security Groups** and route tables
- ✅ **Conflict Prevention** through AVNM IPAM
- ✅ **Scalable Design** - easily add more spokes
- ✅ **Infrastructure as Code** with Terraform

## 📦 **Module Structure**

| Module | Purpose | Resources |
|--------|---------|-----------|
| **`1-hub-spoke-lz`** | Complete networking foundation | • Resource Group<br>• Hub & Spoke VNets<br>• **Azure Virtual Network Manager**<br>• **IPAM Pool (10.1.0.0/14)**<br>• Dynamic Subnet Allocation<br>• Azure Firewall<br>• Network Security Groups<br>• Route Tables<br>• Network Connectivity Configuration |
| **`2-compute`** | Virtual machines and compute | • Virtual Machines<br>• Network Interfaces<br>• Public IPs<br>• Compute-related resources |

## 🚀 **Quick Start**

### **Prerequisites**
- GitHub account
- Azure subscription with Contributor access
- Basic understanding of Azure networking concepts

### **1. Create Codespace**
Navigate to this repository and create a new Codespace:

```bash
# Click "Code" → "Codespaces" → "Create codespace on main"
```

### **2. Azure Authentication**
Login to your Azure account:

```bash
az login
# If you have issues, try:
az login --use-device-code
```

### **3. Configure Environment**
Update the `answers.json` file with your Azure details:

```json
{
  "subscriptionId": "your-subscription-id-here",
  "location": "eastus2",
  "resourceGroupName": "rg-avnm-lab"
}
```

### **4. Deploy Infrastructure**
Run the automated deployment script:

```powershell
./deploy.ps1
```

**Deployment Process:**
1. **Module 1**: Deploys complete networking + AVNM + IPAM (5-10 minutes)
2. **Module 2**: Deploys virtual machines and compute resources (3-5 minutes)

### **5. Verify Deployment**
Check the allocated IP address ranges:

```bash
cd Modules/1-hub-spoke-lz
terraform output spoke_subnet_allocated_prefixes
```

## 🔧 **Configuration Details**

### **IPAM Pool Configuration**
The lab uses Azure Virtual Network Manager's IPAM capabilities:

- **Pool Range**: `10.1.0.0/14` (262,144 total IP addresses)
- **Subnet Allocation**: 32 IPs per spoke subnet (effectively `/27` subnets)
- **Automatic Assignment**: No manual IP planning required
- **Conflict Prevention**: AVNM ensures no overlapping ranges

### **Network Topology**
- **Hub VNet**: `10.1.0.0/16`
  - Azure Firewall Subnet: `10.1.1.0/24`
- **Spoke VNets**: Dynamically allocated from IPAM pool
  - Spoke 1: Automatically assigned `/27` subnet
  - Spoke 2: Automatically assigned `/27` subnet  
  - Spoke 3: Automatically assigned `/27` subnet

### **Security & Routing**
- **Network Security Groups**: Applied to all spoke subnets
- **Route Tables**: Force all traffic through Azure Firewall
- **Firewall Rules**: Allow inter-spoke communication and internet access

## 🔍 **Monitoring & Verification**

### **View Allocated IP Ranges**
```bash
terraform output spoke_subnet_allocated_prefixes
```

### **Check Network Manager Status**
```bash
terraform output network_manager_id
terraform output connectivity_configuration_id
```

### **Azure Portal Verification**
1. Navigate to **Network Manager** in Azure Portal
2. Check **IP Address Management** → **IP Address Pools**
3. View **Configurations** → **Connectivity configurations**
4. Monitor **Deployments** status

## 🧹 **Cleanup**

When finished with the lab, run the destroy script:

```powershell
./destroy.ps1
```

**Destruction Order:**
1. Compute resources (VMs, NICs)
2. Networking infrastructure (VNets, AVNM, Firewall)

## 🔐 **Access Information**

### **Virtual Machine Credentials**
- **Username**: `azureadmin`
- **Password**: `AzureAdmin123!`

### **Firewall Access**
- Access spoke VMs through the hub network
- All traffic is routed through Azure Firewall

## 🛠️ **Advanced Usage**

### **Adding More Spoke Networks**
To add additional spoke networks, update the `terraform.tfvars` file:

```hcl
vnet_name_spokes = [
  "vnet-avnm-spoke1", 
  "vnet-avnm-spoke2", 
  "vnet-avnm-spoke3",
  "vnet-avnm-spoke4"  # Add new spoke
]

address_space_spokes = {
  "vnet-avnm-spoke1" = ["10.1.2.0/24"],
  "vnet-avnm-spoke2" = ["10.1.3.0/24"],
  "vnet-avnm-spoke3" = ["10.1.4.0/24"],
  "vnet-avnm-spoke4" = ["10.1.5.0/24"]  # Add new spoke
}
```

The IPAM pool will automatically allocate subnet ranges for new spokes.

### **Customizing IP Allocation**
Modify subnet IP count in `terraform.tfvars`:

```hcl
subnet_ip_count = "64"  # Allocates /26 subnets instead of /27
```

## 📚 **Learning Objectives**

After completing this lab, you will understand:

- ✅ Azure Virtual Network Manager concepts and capabilities
- ✅ IP Address Management (IPAM) and dynamic allocation
- ✅ Hub-spoke network topology design patterns
- ✅ Azure Firewall configuration and routing
- ✅ Network Security Groups and traffic control
- ✅ Infrastructure as Code best practices with Terraform
- ✅ Automated deployment and destruction workflows

## ⚠️ **Important Notes**

- **Region Support**: Ensure AVNM is available in your chosen region (recommended: `eastus2`)
- **Permissions**: Requires Contributor access to create Network Manager resources
- **VM SKUs**: Default VM size is suitable for most regions, modify if needed
- **Cost Management**: Remember to destroy resources when not in use

## 🤝 **Contributing**

Feel free to submit issues, fork the repository, and create pull requests for improvements.

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Happy Networking!** 🎉

*This lab demonstrates modern Azure networking capabilities with Infrastructure as Code best practices.*
