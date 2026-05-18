# Azure Virtual Network Manager Lab

This lab deploys an Azure Virtual Network Manager (AVNM) hub-and-spoke environment using
the Azure Developer CLI (azd) with Bicep. It is designed to run in GitHub Codespaces, which
provides a pre-configured environment with all required dependencies.

## Architecture

| Resource | Details |
|----------|---------|
| Resource Group | `rg-<environment-name>` |
| Hub VNet | `vnet-avnm-hub` (10.1.0.0/16) |
| Spoke VNets | `vnet-avnm-spoke1/2/3` (10.2-4.0.0/24) |
| Azure Firewall | `azfw-hub` (Standard) - routes all spoke traffic through hub |
| Route Table | `avnm-route-table` - default route next-hop set to firewall |
| Linux VMs | One per spoke (Standard_B2ls_v2, Ubuntu 22.04 LTS) |
| Network Manager | `avnm-demo` - hub-and-spoke connectivity configuration |

## Prerequisites

- GitHub account with access to Codespaces

## Deployment

### 1. Open the Codespace

Navigate to the repository on GitHub, click **Code**, select the **Codespaces** tab, and
click **Create codespace on main**.

### 2. Authenticate with Azure

```sh
az login
azd auth login
```

### 3. Configure the environment

```sh
azd env new avnm-lab
azd env set AZURE_LOCATION eastus2
azd env set AZURE_VM_ADMIN_PASSWORD "<your-password>"
```

> **Note:** Verify that `Standard_B2ls_v2` is available in your chosen region before deploying.
> East US 2 is recommended.

### 4. Deploy

```sh
azd up
```

## Cleanup

```sh
azd down --force --purge
```

## VM Credentials

| Field | Value |
|-------|-------|
| Username | `azureadmin` |
| Password | Value of `AZURE_VM_ADMIN_PASSWORD` set during configuration |

## Repository Structure

```
infra/
├── main.bicep                 # Subscription-scope entry point
├── main.parameters.json       # AZD parameter bindings
└── modules/
    ├── hub-spoke-lz.bicep     # Hub VNet, firewall, route table, spoke VNets/subnets
    ├── compute.bicep          # Network interfaces and Linux VMs per spoke
    └── avnm.bicep             # Network Manager and connectivity configuration
```
