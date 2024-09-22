readme
# Azure Virtual Network Manager Lab

This Terraform lab environment will deploy an Azure Virtual Network Manager (AVNM) lab. This lab uses GitHub Codespaces which allows you to deploy a containerized dev environment with all dependencies included. Follow the steps below to deploy and manage the lab environment.

## Prerequisites
- GitHub account

## Steps to Deploy the Lab

1. **Create a Codespace from the GitHub Repository**

   - Navigate to the GitHub repository for this lab.
   - Click on the `Code` button.
   - Select the `Codespaces` tab.
   - Click on `Create codespace on main` (or the appropriate branch).

2. **Login to Azure**

   Open a terminal in the Codespace and run the following command to login to your Azure account:

   ```sh
   az login