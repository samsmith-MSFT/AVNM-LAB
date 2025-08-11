# Updated Deployment Scripts for Simplified Architecture

## 🚀 **What Changed**

The deployment and destroy scripts have been updated to reflect the simplified 2-module architecture:

### **Before (3 modules):**
- `deploy.ps1`: 1-hub-spoke-lz → 2-compute → 3-avnm
- `destroy.ps1`: 3-avnm → 2-compute → 1-hub-spoke-lz

### **After (2 modules):**
- `deploy.ps1`: 1-hub-spoke-lz → 2-compute
- `destroy.ps1`: 2-compute → 1-hub-spoke-lz

## 📋 **Script Updates**

### **deploy.ps1**
- ✅ Removed references to `3-avnm` module
- ✅ Updated deployment order to only include 2 modules
- ✅ Added comments explaining the simplified architecture
- ✅ All AVNM functionality now deployed as part of `1-hub-spoke-lz`

### **destroy.ps1** 
- ✅ Removed references to `3-avnm` module
- ✅ Fixed duplicate destruction logic (was running twice)
- ✅ Updated destruction order (reverse of deployment)
- ✅ Added comments explaining the process

## 🎯 **Usage**

### **Deploy Everything:**
```powershell
.\deploy.ps1
```
This will:
1. Deploy `Modules/1-hub-spoke-lz` (networking + AVNM + IPAM)
2. Deploy `Modules/2-compute` (VMs and compute resources)

### **Destroy Everything:**
```powershell
.\destroy.ps1
```
This will:
1. Destroy `Modules/2-compute` first (compute resources)
2. Destroy `Modules/1-hub-spoke-lz` last (networking infrastructure)

## ✨ **Benefits**

- **Faster Deployment**: No unnecessary 3rd module to deploy
- **Cleaner Dependencies**: All related networking resources deploy together
- **Simpler Maintenance**: Only 2 modules to manage
- **Better Reliability**: Reduced chance of dependency issues

## 📝 **Configuration**

The scripts automatically read from `answers.json` and update the `terraform.tfvars` files with the correct subscription ID, location, and resource group name before deployment.

Make sure your `answers.json` contains:
```json
{
  "subscriptionId": "your-subscription-id",
  "location": "your-preferred-location", 
  "resourceGroupName": "your-resource-group-name"
}
```
