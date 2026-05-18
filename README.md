# Azure Virtual Network Manager Lab

This lab deploys an Azure Virtual Network Manager (AVNM) hub-and-spoke environment using
**Azure Developer CLI (azd)** with Bicep. It uses GitHub Codespaces so all dependencies are
included — no local installs required.

## What Gets Deployed

| Resource | Details |
|----------|---------|
| Resource Group | `rg-<environment-name>` |
| Hub VNet | `vnet-avnm-hub` (10.1.0.0/16) |
| Spoke VNets | `vnet-avnm-spoke1/2/3` (10.2–4.0.0/24) |
| Azure Firewall | `azfw-hub` (Standard) — routes all spoke traffic |
| Route Table | `avnm-route-table` — next-hop = firewall |
| Linux VMs | One per spoke (`Standard_B2ls_v2`, Ubuntu 22.04 LTS) |
| Network Manager | `avnm-demo` — hub-and-spoke connectivity config |

## Prerequisites

- GitHub account (for Codespaces)

## Steps to Deploy

1. **Open the Codespace**

   Click **Code → Codespaces → Create codespace on main**.

2. **Login to Azure**

   ```sh
   az login
   azd auth login
   ```

3. **Create an AZD environment and set variables**

   ```sh
   azd env new avnm-lab
   azd env set AZURE_LOCATION eastus2
   azd env set AZURE_VM_ADMIN_PASSWORD "AzureAdmin123!"
   ```

   > **Tip:** Change `eastus2` to any region that supports `Standard_B2ls_v2` VMs.

4. **Deploy everything**

   ```sh
   azd up
   ```

   Or using the provided script:

   ```sh
   ./deploy.ps1
   ```

## Clean Up

```sh
azd down --force --purge
```

Or:

```sh
./destroy.ps1
```

## Azure VM Login Info

| Field | Value |
|-------|-------|
| Username | `azureadmin` |
| Password | value of `AZURE_VM_ADMIN_PASSWORD` (default: `AzureAdmin123!`) |

## Infrastructure Layout

```
infra/
├── main.bicep                 # Subscription-scope entry point
├── main.parameters.json       # AZD parameter bindings
└── modules/
    ├── hub-spoke-lz.bicep     # Hub VNet, firewall, route table, spoke VNets/subnets
    ├── compute.bicep          # NICs + Linux VMs per spoke
    └── avnm.bicep             # Network Manager + connectivity config
```

> **Note:** The `Modules/` directory contains the original Terraform code and can be safely
> deleted once you've verified the Bicep deployment.

Happy deploying!
