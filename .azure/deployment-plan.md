# AVNM-LAB AZD Migration Plan

## Status: Ready for Validation

## Overview

Convert existing Terraform-based AVNM-LAB deployment to Azure Developer CLI (AZD) with Bicep IaC,
replacing the `deploy.ps1` / `destroy.ps1` / `answers.json` workflow with `azd up` / `azd down`.

## Current State

| Component | Current |
|-----------|---------|
| IaC | Terraform (3 sequential modules) |
| Deploy | `deploy.ps1` reads `answers.json`, runs `terraform apply` |
| Destroy | `destroy.ps1` runs `terraform destroy` |
| Config | `answers.json` (subscriptionId, location, resourceGroupName) |

## Target State

| Component | Target |
|-----------|--------|
| IaC | Bicep (`infra/main.bicep` + `infra/modules/`) |
| Deploy | `azd up` |
| Destroy | `azd down` |
| Config | `azd env set` / AZD environment variables |

## Architecture

Resources deployed (unchanged from Terraform):
- **Resource Group**: `rg-{environmentName}`
- **Hub VNet**: `vnet-avnm-hub` (10.1.0.0/16) + AzureFirewallSubnet (10.1.1.0/24)
- **Spoke VNets**: `vnet-avnm-spoke1/2/3` (10.2–4.0.0/24), each with a /27 subnet
- **Azure Firewall**: `azfw-hub` with firewall policy + allow rule (RFC1918 → RFC1918)
- **Route Table**: `avnm-route-table` forcing traffic through the firewall
- **Linux VMs**: one per spoke (`Standard_B2ls_v2`, Ubuntu 22.04 LTS)
- **Azure Virtual Network Manager**: `avnm-demo` with hub-and-spoke connectivity config

## IaC Provider

Bicep (AZD default) — Terraform modules (`Modules/`) will be superseded.

## Files to Create

| File | Purpose |
|------|---------|
| `azure.yaml` | AZD project manifest |
| `infra/main.bicep` | Subscription-scope entry point |
| `infra/main.parameters.json` | AZD parameter values |
| `infra/modules/hub-spoke-lz.bicep` | Hub VNet, firewall, route table, spoke VNets/subnets |
| `infra/modules/compute.bicep` | NICs + Linux VMs per spoke |
| `infra/modules/avnm.bicep` | Network Manager, network group, connectivity config |

## Files to Update

| File | Change |
|------|--------|
| `deploy.ps1` | Replaced with `azd up` wrapper |
| `destroy.ps1` | Replaced with `azd down` wrapper |
| `README.md` | Updated with AZD deployment instructions |

## Key Decisions

- `answers.json` replaced by `azd env set` (AZURE_ENV_NAME, AZURE_LOCATION, AZURE_VM_ADMIN_PASSWORD)
- Resource group name derived from `rg-{environmentName}` (AZD convention)
- Terraform `Modules/` directory left in place for reference; can be deleted once Bicep is verified
- VM admin password passed as `@secure()` Bicep param, set via `azd env set AZURE_VM_ADMIN_PASSWORD`
- Default network values (VNet names, CIDRs) baked into `main.bicep` parameter defaults (lab-specific)

## Deployment Steps (After Migration)

```sh
# 1. Login
az login
azd auth login

# 2. Create environment
azd env new avnm-lab

# 3. Set location and VM password
azd env set AZURE_LOCATION eastus2
azd env set AZURE_VM_ADMIN_PASSWORD "AzureAdmin123!"

# 4. Deploy everything
azd up

# 5. Tear down
azd down --force --purge
```
