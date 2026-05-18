# Deploy AVNM Lab using Azure Developer CLI (azd)
# Replaces the previous Terraform-based deploy workflow.
#
# Prerequisites:
#   az login
#   azd auth login

Write-Host "=== AVNM Lab Deployment ===" -ForegroundColor Cyan

# Create an azd environment if one doesn't exist
$envList = azd env list 2>$null
if (-not $envList -or $envList -notmatch '\S') {
    Write-Host "No AZD environment found. Creating 'avnm-lab'..."
    azd env new avnm-lab
}

# Prompt for VM admin password if not already set
$adminPassword = azd env get-value AZURE_VM_ADMIN_PASSWORD 2>$null
if (-not $adminPassword) {
    $securePassword = Read-Host "Enter VM admin password (default: AzureAdmin123!)" -AsSecureString
    if ($securePassword.Length -eq 0) {
        $adminPassword = "AzureAdmin123!"
    } else {
        $adminPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
        )
    }
    azd env set AZURE_VM_ADMIN_PASSWORD $adminPassword
}

Write-Host "Running azd up..." -ForegroundColor Green
azd up