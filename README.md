# 🌐 Azure Virtual Network Manager (AVNM) Lab with IP Address Management

[![Terraform](https://img.shields.io/badge/Terraform-1.x-blue.svg)](https://www.terraform.io/)
[![Azure](https://img.shields.io/badge/Azure-Cloud-blue.svg)](https://azure.microsoft.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A comprehensive Terraform lab environment that demonstrates **Azure Virtual Network Manager (AVNM)** with advanced **IP Address Management (IPAM)**, **Security Admin Rules**, and **UDR (Routing) Management** capabilities. This lab showcases modern cloud networking patterns including hub-spoke topology, dynamic subnet allocation, centrally enforced security policies, and AVNM-managed routing.

## 🏗️ **Architecture Overview**

This lab deploys a **3-module architecture** that creates a complete hub-spoke network topology with automatic IP address management, centrally enforced security admin rules, and AVNM-managed routing:

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
- ✅ **Dynamic IP Allocation** from centralized IPAM pool (`10.0.0.0/14`)
- ✅ **Automatic Subnet Management** - no manual IP planning required
- ✅ **Azure Firewall** with routing and security rules
- ✅ **Network Security Groups** and route tables
- ✅ **Conflict Prevention** through AVNM IPAM
- ✅ **Scalable Design** - easily add more spokes
- ✅ **Security Admin Rules** - centrally enforced security policies that override NSGs
- ✅ **UDR Management** - AVNM-managed routing configuration pushed to spoke VNets
- ✅ **Infrastructure as Code** with Terraform

## 📦 **Module Structure**

| Module | Purpose | Resources |
|--------|---------|----------|
| **`1-hub-spoke-lz`** | Complete networking foundation | • Resource Group<br>• Hub & Spoke VNets<br>• **Azure Virtual Network Manager**<br>• **IPAM Pool (10.0.0.0/14)**<br>• Dynamic Subnet Allocation<br>• Azure Firewall<br>• Network Security Groups<br>• Route Tables<br>• Network Connectivity Configuration |
| **`2-compute`** | Virtual machines and compute | • Virtual Machines<br>• Network Interfaces<br>• Public IPs<br>• Compute-related resources |
| **`3-avnm`** | Security & routing policies | • **Security Admin Configuration**<br>• **Admin Rule Collections & Rules** (ICMP allow, SSH/RDP deny, high-risk port deny, internal allow)<br>• **Routing Configuration** (UDR Management)<br>• **Routing Rule Collections & Rules** (internet via firewall, spoke-to-spoke via firewall)<br>• SecurityAdmin & Routing Deployments |

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

> **⚠️ Important**: After updating the `answers.json` file, make sure to **save the file** by pressing `Ctrl+S` (Windows/Linux) or `Cmd+S` (Mac) before proceeding to the next step. The deployment scripts rely on the saved values in this file.

### **4. Deploy Infrastructure**
Run the automated deployment script:

```powershell
./deploy.ps1
```

**Deployment Process:**
1. **Module 1**: Deploys complete networking + AVNM + IPAM (5-10 minutes)
2. **Module 2**: Deploys virtual machines and compute resources (3-5 minutes)
3. **Module 3**: Deploys Security Admin Rules + Routing Configuration (2-3 minutes)

### **5. Verify Deployment**
Check the allocated IP address ranges:

```bash
cd Modules/1-hub-spoke-lz
terraform output spoke_subnet_allocated_prefixes
```

## 🔧 **Configuration Details**

### **IPAM Pool Configuration**
The lab uses Azure Virtual Network Manager's IPAM capabilities for **complete dynamic allocation**:

- **Pool Range**: `10.0.0.0/14` (262,144 total IP addresses)
- **Hub VNet Allocation**: 65,536 IPs (effectively `/16` VNet)
- **Spoke VNet Allocation**: 256 IPs per spoke VNet (effectively `/24` VNets)
- **Firewall Subnet Allocation**: 256 IPs (effectively `/24` subnet)
- **Spoke Subnet Allocation**: 32 IPs per spoke subnet (effectively `/27` subnets)
- **Automatic Assignment**: No manual IP planning required
- **Conflict Prevention**: AVNM ensures no overlapping ranges

### **Network Topology**
- **Hub VNet**: Dynamically allocated from IPAM pool (gets `/16` range)
  - Azure Firewall Subnet: Dynamically allocated (gets `/24` range)
- **Spoke VNets**: Dynamically allocated from IPAM pool
  - Spoke 1: Automatically assigned `/24` VNet
  - Spoke 2: Automatically assigned `/24` VNet  
  - Spoke 3: Automatically assigned `/24` VNet
- **Spoke Subnets**: Dynamically allocated within their VNets
  - Each subnet gets automatically assigned `/27` subnet

### **Security & Routing**
- **Network Security Groups**: Applied to all spoke subnets
- **Security Admin Rules** (AVNM-enforced, cannot be overridden by NSGs):
  - **AlwaysAllow ICMP**: Ensures diagnostics always work
  - **Deny SSH from Internet**: Blocks port 22 from internet
  - **Deny RDP from Internet**: Blocks port 3389 from internet
  - **Deny High-Risk Outbound**: Blocks Telnet (23) and FTP (20, 21) outbound
  - **Allow Internal Traffic**: Permits RFC1918 (10.0.0.0/8) inbound
- **AVNM UDR Management** (centrally managed routing):
  - **Internet via Firewall**: Routes 0.0.0.0/0 through Azure Firewall
  - **Private via Firewall**: Routes 10.0.0.0/8 through Azure Firewall for inspection
- **Route Tables**: Force all traffic through Azure Firewall (legacy, complemented by AVNM routing)
- **Firewall Rules**: Allow inter-spoke communication and internet access

## 🔍 **Monitoring & Verification**

### **View Allocated IP Ranges**
```bash
# View hub VNet allocation
terraform output hub_vnet_allocated_prefixes

# View spoke VNet allocations
terraform output spoke_vnet_allocated_prefixes

# View firewall subnet allocation
terraform output firewall_subnet_allocated_prefixes

# View spoke subnet allocations
terraform output spoke_subnet_allocated_prefixes
```

### **Check Network Manager Status**
```bash
terraform output network_manager_id
terraform output connectivity_configuration_id
```

### **Check Security Admin & Routing (Module 3)**
```bash
cd Modules/3-avnm
terraform output security_admin_configuration_id
terraform output routing_configuration_id
terraform output security_rules
terraform output routing_rules
```

### **Azure Portal Verification**
1. Navigate to **Network Manager** in Azure Portal
2. Check **IP Address Management** → **IP Address Pools**
3. View **Configurations** → **Connectivity configurations**
4. View **Configurations** → **Security admin configurations** → see enforced rules
5. View **Configurations** → **Routing configurations** → see UDR rules
6. Monitor **Deployments** status (Connectivity, SecurityAdmin, Routing)

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
```

The IPAM pool will automatically allocate VNet and subnet ranges for new spokes.

### **Customizing IP Allocation**
Modify IP allocation in `terraform.tfvars`:

```hcl
hub_vnet_ip_count = "131072"        # Allocates /15 hub VNet instead of /16
vnet_ip_count = "512"               # Allocates /23 spoke VNets instead of /24
firewall_subnet_ip_count = "512"    # Allocates /23 firewall subnet instead of /24
subnet_ip_count = "64"              # Allocates /26 spoke subnets instead of /27
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
