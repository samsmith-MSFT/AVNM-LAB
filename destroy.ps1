# AVNM Lab Destruction Script
# 3-module architecture - destroys in reverse order:
# 1. avnm: Security Admin Rules + UDR Management (destroyed first)
# 2. compute: Virtual machines and compute resources
# 3. hub-spoke-lz: Complete networking infrastructure + AVNM + IPAM (destroyed last)

# Change to the modules directory
$null = cd /workspaces/AVNM-LAB

# Define the destroy order (reverse of deploy order - 3 modules)
$order = @("3-avnm", "2-compute", "1-hub-spoke-lz")

# Change to the modules directory
Set-Location -Path "Modules"

# Get the root directory
$rootDir = Get-Location

foreach ($dir in $order) {
    # Construct the full path to the directory
    $fullPath = Join-Path -Path $rootDir -ChildPath $dir
    
    if (Test-Path -Path $fullPath) {
        # Navigate to the directory
        Set-Location -Path $fullPath
        
        Write-Host "Running terraform destroy in $fullPath"
        
        # Run terraform destroy with auto-approve
        terraform destroy -auto-approve
        
        # Navigate back to the root directory
        Set-Location -Path $rootDir
    } else {
        Write-Host "Directory $fullPath not found"
    }
}
