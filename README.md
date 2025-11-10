# Remove-PrimaryUserFromMultipleDevices
This script connects to Microsoft Graph and removes the Primary User associated with each specified Intune device.
It reads device names from a text file, retrieves the current user association, and performs a DELETE operation via Graph API.
Designed for automation workflows, bulk device cleanup, and user reassignment scenarios.

## Prerequisites
- Install the MS Graph PowerShell Module
- Ensure you have enough privileges to run the script 
- Always run the script as an administrator 
## Connect me
Sujin Nelladath - https://www.linkedin.com/in/sujin-nelladath-8911968a
