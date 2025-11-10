<#

.SYNOPSIS

Removes the Primary User from one or more Intune-managed devices using a list of machine names.

.DESCRIPTION

This script connects to Microsoft Graph and removes the Primary User associated with each specified Intune device.
It reads device names from a text file, retrieves the current user association, and performs a DELETE operation via Graph API.
Designed for automation workflows, bulk device cleanup, and user reassignment scenarios.

.AUTHOR
Sujin Nelladath — Microsoft Graph MVP

.PARAMETER DeviceListPath

Mandatory. Path to the text file containing device names (one per line).

.EXAMPLE

Remove Primary Users from devices listed in C:\Temp\devices.txt:
.\Remove-IntunePrimaryUsers.ps1 -DeviceListPath "C:\Temp\devices.txt"

.NOTES

Requires Microsoft.Graph modules and the DeviceManagementManagedDevices.ReadWrite.All permission scope.
Uses the beta endpoint for user removal via `$ref`.

#>

param
(
    [Parameter(Mandatory = $true)]
    [string]$DeviceListPath
)

# Check if Microsoft Graph module is installed
if (!(Get-Module -ListAvailable -Name Microsoft.Graph.Authentication))

{
    Write-Error "Microsoft Graph module not installed. Run: Install-Module Microsoft.Graph"
    exit 1
}

# Import modules
Import-Module Microsoft.Graph.Authentication
Import-Module Microsoft.Graph.DeviceManagement

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..."
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"

# Read device names from file
$DeviceNames = Get-Content -Path $DeviceListPath

foreach ($MachineName in $DeviceNames) 

{
    Write-Host "Processing device: $MachineName"

    # Find the device by name
    $Uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?$filter=deviceName eq '$MachineName'"
    $Response = Invoke-MgGraphRequest -Method GET -Uri $Uri

    $devicename = $Response.value | Where-Object { $_.deviceName -eq $MachineName }
    $deviceId   = $devicename.id

    if (!$devicename) 
    
    {
        Write-Error "Device '$MachineName' not found in Intune"
        continue
    }

    Write-Host "Found device: $($devicename.deviceName) (ID: $($deviceId))"

    # Get current primary users
    $UsersUri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices('$($deviceId)')/users"
    $UsersResponse = Invoke-MgGraphRequest -Method GET -Uri $UsersUri
    $PrimaryUsers = $UsersResponse.value

    if ($PrimaryUsers.Count -eq 0) 
    
        {
            Write-Host "No primary users found for this device"
        }

    else
    
     {
        Write-Host "Found $($PrimaryUsers.Count) user(s) associated with device"
        Write-Host "$($PrimaryUsers.displayName) will be removed as primary user" -ForegroundColor Yellow

        try 
        
            {
                # Remove primary user
                $RemoveUri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($deviceId)/users/`$ref"
                Invoke-MgGraphRequest -Method DELETE -Uri $RemoveUri
                Write-Host "Successfully removed primary user from device" -ForegroundColor Green
            }
        catch 
        
            {
                Write-Error "Failed to remove primary user: $($_.Exception.Message)"
            }
    }
}

Write-Host "Disconnecting from Microsoft Graph..."
Disconnect-MgGraph

Write-Host "Script completed."