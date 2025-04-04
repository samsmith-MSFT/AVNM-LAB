# Change to the modules directory
$null = cd /workspaces/AVNM-LAB

# Read the answers.json file
$answers = Get-Content -Raw -Path "answers.json" | ConvertFrom-Json

# Extract values
$subscriptionId = $answers.subscriptionId
$location = $answers.location
$resourceGroupName = $answers.resourceGroupName

# Find all terraform.tfvars files in the module directories
$tfvarsFiles = Get-ChildItem -Recurse -Filter "terraform.tfvars" | Sort-Object DirectoryName

# Define the order of directories
$order = @("1-hub-spoke-lz", "2-compute", "3-avnm")

foreach ($dir in $order) {
    $tfvarsFile = $tfvarsFiles | Where-Object { $_.DirectoryName -like "*$dir*" }
    
    if ($tfvarsFile) {
        Write-Host "Updating $($tfvarsFile.FullName)"
        
        # Read the existing content of the terraform.tfvars file
        $content = Get-Content -Path $tfvarsFile.FullName
        
        # Update the specific values
        $updatedContent = $content -replace 'subscription_id\s*=\s*".*"', "subscription_id = `"$subscriptionId`""
        $updatedContent = $updatedContent -replace 'location\s*=\s*".*"', "location = `"$location`""
        $updatedContent = $updatedContent -replace 'resource_group_name\s*=\s*".*"', "resource_group_name = `"$resourceGroupName`""
        
        # Write the updated content back to the terraform.tfvars file
        Set-Content -Path $tfvarsFile.FullName -Value $updatedContent
        
        # Navigate to the directory containing the terraform.tfvars file
        Set-Location -Path $tfvarsFile.DirectoryName
        
        # Run terraform init
        Write-Host "Running terraform init in $($tfvarsFile.DirectoryName)"
        terraform init
        
        # Run terraform apply with auto-approve
        Write-Host "Running terraform apply in $($tfvarsFile.DirectoryName)"
        terraform apply -auto-approve
        
        # Navigate back to the root directory
        Set-Location -Path (Get-Location).Path
    } else {
        Write-Host "No terraform.tfvars file found for directory $dir"
    }
}
