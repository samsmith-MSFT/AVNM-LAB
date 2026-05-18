# Destroy AVNM Lab using Azure Developer CLI (azd)
# Replaces the previous Terraform-based destroy workflow.

Write-Host "=== AVNM Lab Teardown ===" -ForegroundColor Yellow
Write-Host "This will delete ALL lab resources." -ForegroundColor Yellow

azd down --force --purge
