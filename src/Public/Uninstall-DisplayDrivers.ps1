# Require script to be run with PowerShell version 5.0 or higher
#Requires -Version 5.0

#Require script to be run as an Administrator
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Uninstall driver packages for the "display" device class utilizing "devcon.exe" on Windows 7 or
    newer devices.  This script is intended for use with Microsoft Endpoint Configuration Manager (MECM)
    and will exit with a return code of 0 if successful, or 1 if an error occurs.  This script will
    also exit if you attempt to run it on a virtual machine, and as such, is intended for physical
    computers only.

    Devcon.exe is superior to using pnputil.exe as pnputil.exe requires that you know the exact
    name of the oem.inf (driver package) file that you wish to uninstall, which is unique to every
    install.  With devcon.exe, you can easily uninstall the oem.inf file by only needing to know the
    hardware id of the device you wish to uninstall the driver package for. In addition to this, devcon.exe
    allows you to easily determine the hardware id of display adapters by specifying the class of device,
    which in this case would be the "display" device class.

.DESCRIPTION
    Scope Assurance: In its current form, this script is only capable of removing display drivers.

    This script, which must be run as an Administrator, provides easy and reliable removal of display
    device driver packages by using the "devcon.exe" utility. The script will find all display devices
    and their hardware ids, and then uninstall the driver package for each device.

    Please note that the "devcon.exe" utility must be present in the same directory as this script.
    Details on where to obtain "devcon.exe" and how it is used are provided in the .LINK section.

    Display driver package removal is performed by the following steps:
    1. List all display devices and their hardware ids using "devcon.exe listclass display".

        Sample Output:
        PCI\VEN_8086&DEV_3E98&SUBSYS_09611028&REV_02\3&11583659&0&10: Intel(R) UHD Graphics 630
        PCI\VEN_10DE&DEV_1E84&SUBSYS_C7231028&REV_A1\4&45D1E59&0&0008: NVIDIA GeForce RTX 2070 SUPER

    2.  Uninstall the driver package for each device using "devcon.exe remove <device hardware id>".
    
        Explanation:
        Each line of Step 1. output is taken as an invidual line, and the hardware ids
        are then passed to "devcon.exe remove <device hardware id>," which then locates
        the driver package for that hardware id and uninstalls it.  From the sample output
        shown in Step 1, the hardware ids that would be passed to "devcon.exe remove" are:
        - PCI\VEN_8086&DEV_3E98&SUBSYS_09611028&REV_02
        - PCI\VEN_10DE&DEV_1E84&SUBSYS_C7231028&REV_A1

.PARAMETER WhatIf
    Used to test the script without actually removing driver packages.

.INPUTS
    Not applicable

.OUTPUTS
    None. This script writes status messages to the console but does not return objects.
    
.EXAMPLE
    Testing the script without actually removing driver packages.
    PS C:\> .\Uninstall-DisplayDrivers.ps1 -WhatIf
        
    Running the script and removing driver packages.
    PS C:\> .\Uninstall-DisplayDrivers.ps1

.LINK
    This script was created with the assistance of GitHub Copilot in VS Code.
    https://code.visualstudio.com/docs/copilot/overview

    How do I obtain devcon.exe?     
    https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/devcon

    How do I use devcon.exe to list display device hardware ids?
    https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/devcon-listclass

    How do I use devcon.exe to remove a driver package using the device hardware id?
    https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/devcon-remove

.NOTES
    Exit Codes:
        0 = Success
        1 = General Failure
        2 = Dependency Missing (devcon.exe not found)
        3 = VM Detected (script blocked on virtual machines)
        4 = Devcon listclass failed

    Exit Code Handling:
        The script initializes $ExitCode to 0 (Success).
        If any error or guardrail condition occurs during execution,
        $ExitCode is updated to reflect the specific failure type.
        At termination, the script exits with the current value of $ExitCode.
    
    Regex Patterns (for reference):
        Active in this script:
            PCI:    ^PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4}(?:&SUBSYS_[0-9A-F]{8})?(?:&REV_[0-9A-F]{2})?

        Documented for future reuse:
            USB:    ^USB\\VID_[0-9A-F]{4}&PID_[0-9A-F]{4}(?:&REV_[0-9A-F]{4})?
            ACPI:   ^ACPI\\[A-Z0-9]{4}(?:&\w{4})?

    Author: David R. Cushman
    Created: 11/27/2025
    Version: 1.0
    Purpose: Created as part of professional development and automation portfolio
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    
)

# Set the initial exit code to 0 (Success)
# If errors do occur later, $ExitCode will be updated to reflect the specific failure
$ExitCode = 0

# Obtain SystemInfo from current computer
$systemInfo = Get-CimInstance -ClassName Win32_ComputerSystem

# Obtain Manufacturer from $systemInfo
$manufacturer = $systemInfo.Manufacturer

# Obtain Model from $systemInfo
$model = $systemInfo.Model

# List of common virtual machine manufacturers/models
$vmManufacturers = @("Microsoft Corporation", "VMware, Inc.", "Xen", "innotek GmbH", "Red Hat", "Oracle Corporation")

# The regex pattern for PCI devices, which corresponds with the "Display" driver class
$pciRegex = '^PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4}(?:&SUBSYS_[0-9A-F]{8})?(?:&REV_[0-9A-F]{2})?'

# Check if the manufacturer or model is in the list of virtual machine manufacturers/models and throw error if true
if ($vmManufacturers -contains $manufacturer -or $vmManufacturers -contains $model) {
    Write-Output "This script cannot be run on a virtual machine."
    $ExitCode = 3
    exit $ExitCode
}
else {
    # Write output to the console indicating that the script is running on a physical machine
    Write-Output "Running on a physical machine."
}

# Define the full path to devcon.exe (expected in same directory as script)
$devconPath = Join-Path -Path $PSScriptRoot -ChildPath "devcon.exe"

# Verify devcon.exe exists
if (-not (Test-Path -Path $devconPath -PathType Leaf)) {
    Write-Output "Error: devcon.exe not found in script directory ($PSScriptRoot)."
    $ExitCode = 2   # Custom exit code for 'dependency missing'
    exit $ExitCode
}
else {
    Write-Output "Found devcon.exe at $devconPath"
}

# Attempt to query display devices class with devcon.exe
try {
    Write-Output "Querying display devices with devcon.exe..."
    $output = & $devconPath listclass display 2>&1

    if (-not $output) {
        throw "devcon.exe returned no output when listing display devices."
    }

    Write-Output "Successfully retrieved display device list."
}
catch {
    Write-Error "Failed to query display devices: $($_.Exception.Message)"
    $ExitCode = 4   # Custom code for 'listclass failed'
    exit $ExitCode
}

try {
    # Split devcon output into lines
    $outputLines = $output -split "`n"

    foreach ($line in $outputLines) {
        $trimmedLine = $line.Trim()

        # Regex match for valid PCI hardware IDs
        if ($trimmedLine -match $pciRegex) {
            $hardwareID = $Matches[0]

            # Use ShouldProcess for WhatIf/Confirm support
            if ($PSCmdlet.ShouldProcess($hardwareID, "Remove display driver")) {
                Write-Output "Removing driver package: $hardwareID"

                # Call devcon.exe to remove the driver
                $removeOutput = & $devconPath remove $hardwareID 2>&1
                Write-Output $removeOutput

                # Check exit code from devcon
                if ($LASTEXITCODE -ne 0) {
                    throw "devcon.exe failed to remove $hardwareID (exit code $LASTEXITCODE)."
                }
            }
        }
        else {
            Write-Output "Info: Skipping line (no valid hardware ID pattern found): '$trimmedLine'"
        }
    }

    Write-Output "Script completed successfully."
    exit $ExitCode
}
catch {
    Write-Error "Script failed with error: $($_.Exception.Message)"
    $ExitCode = 1
    exit $ExitCode
}
