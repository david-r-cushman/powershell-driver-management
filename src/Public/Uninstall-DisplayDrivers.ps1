# Require script to be run with PowerShell version 5.0 or higher
#Requires -Version 5.0

<#
.SYNOPSIS
    Uninstalls display driver packages by using devcon.exe and returns ConfigMgr-friendly exit codes.

.DESCRIPTION
    Scope Assurance: In its current form, this script is only capable of removing display drivers.

    This script is intended to be deployed as a script in Microsoft Configuration Manager
    (ConfigMgr / MECM), not as a package or program. It remains a single self-contained `.ps1`
    file so it can be imported and executed through the ConfigMgr Scripts feature while still
    returning explicit exit codes that can be collected in execution status reporting.

    The script must run in an elevated administrative context on a physical computer.
    It blocks execution on known virtual machine platforms and verifies that `devcon.exe`
    is present in the same directory as the script before attempting any driver removal.

    Driver removal is performed in two phases:
    1. Query display-class devices with `devcon.exe listclass display`.
    2. Extract matching PCI hardware IDs from the returned lines and call
       `devcon.exe remove <hardware-id>` for each matching display adapter.

    `devcon.exe` is used because it can enumerate devices by class and remove the
    corresponding driver package by hardware ID, avoiding the need to know the
    environment-specific `oem*.inf` name in advance.

.PARAMETER WhatIf
    Shows what driver removals would occur without actually removing any driver packages.

.INPUTS
    Not applicable

.OUTPUTS
    None. This script writes status messages to the information stream and exits with a numeric code.

.EXAMPLE
    Preview the display driver removals without making changes.
    PS C:\> .\Uninstall-DisplayDrivers.ps1 -WhatIf

    Example result:
    The script enumerates display adapters, reports the hardware IDs it would target,
    and exits without removing any driver packages.

.EXAMPLE
    Run the script in an elevated context to remove display driver packages.
    PS C:\> .\Uninstall-DisplayDrivers.ps1

    Example result:
    The script locates `devcon.exe`, enumerates display devices, removes matching driver
    packages, and exits with `0` on success.

.EXAMPLE
    Review the script from ConfigMgr execution status by using its exit code mapping.
    PS C:\> .\Uninstall-DisplayDrivers.ps1

    Example result:
    ConfigMgr records the script outcome based on the process exit code returned by the script.

.LINK
    How do I obtain devcon.exe?
    https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/devcon

.LINK
    How do I use devcon.exe to list display device hardware ids?
    https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/devcon-listclass

.LINK
    How do I use devcon.exe to remove a driver package using the device hardware id?
    https://learn.microsoft.com/en-us/windows-hardware/drivers/devtest/devcon-remove

.LINK
    Create and run PowerShell scripts from the Configuration Manager console.
    https://learn.microsoft.com/en-us/intune/configmgr/apps/deploy-use/create-deploy-scripts

.NOTES
    Exit Codes:
        0 = Success
        1 = General Failure
        2 = Dependency Missing (`devcon.exe` not found)
        3 = Virtual Machine Detected
        4 = `devcon.exe listclass display` failed
        5 = Administrative Context Required

    Runtime Requirements:
        - PowerShell 5.0 or higher
        - Elevated administrative context
        - Physical computer
        - `devcon.exe` present in the same directory as the script

    ConfigMgr Considerations:
        - designed for ConfigMgr Scripts deployment as a single `.ps1` file
        - uses process exit codes so client reporting reflects success or failure states
        - supports `-WhatIf` through `ShouldProcess` for safer validation and testing

    PCI Hardware ID Pattern:
        ^PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4}(?:&SUBSYS_[0-9A-F]{8})?(?:&REV_[0-9A-F]{2})?

    Author: David R. Cushman
    Created: 11/27/2025
    Version: 1.0
    Purpose: Created as part of professional development and automation portfolio
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    
)

$script:DisplayDriverVmManufacturers = @(
    'Microsoft Corporation',
    'VMware, Inc.',
    'Xen',
    'innotek GmbH',
    'Red Hat',
    'Oracle Corporation'
)

$script:DisplayDriverPciRegex = '^PCI\\VEN_[0-9A-F]{4}&DEV_[0-9A-F]{4}(?:&SUBSYS_[0-9A-F]{8})?(?:&REV_[0-9A-F]{2})?'

function Get-DisplayDriverComputerSystem {
    [CmdletBinding()]
    param ()

    Get-CimInstance -ClassName Win32_ComputerSystem
}

function Test-DisplayDriverAdministrativeContext {
    [CmdletBinding()]
    param ()

    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $currentPrincipal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)

    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-DisplayDriverVirtualMachine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [psobject]$ComputerSystem
    )

    return (
        $script:DisplayDriverVmManufacturers -contains $ComputerSystem.Manufacturer -or
        $script:DisplayDriverVmManufacturers -contains $ComputerSystem.Model
    )
}

function Get-DisplayDriverDevConPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ScriptRoot
    )

    $devconPath = Join-Path -Path $ScriptRoot -ChildPath 'devcon.exe'

    if (-not (Test-Path -Path $devconPath -PathType Leaf)) {
        throw [System.IO.FileNotFoundException]::new("Error: devcon.exe not found in script directory ($ScriptRoot).")
    }

    return $devconPath
}

function Invoke-DisplayDriverDevCon {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$DevConPath,

        [Parameter(Mandatory)]
        [string[]]$ArgumentList
    )

    $output = & $DevConPath @ArgumentList 2>&1

    [pscustomobject]@{
        Output   = @($output)
        ExitCode = $LASTEXITCODE
    }
}

function Get-DisplayHardwareIdFromLine {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Line
    )

    $trimmedLine = $Line.Trim()

    if ($trimmedLine -match $script:DisplayDriverPciRegex) {
        return $Matches[0]
    }

    return $null
}

function Invoke-UninstallDisplayDrivers {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [string]$ScriptRoot = $PSScriptRoot
    )

    if (-not (Test-DisplayDriverAdministrativeContext)) {
        Write-Information 'This script must be run in an elevated administrative context.'
        return 5
    }

    $systemInfo = Get-DisplayDriverComputerSystem

    if (Test-DisplayDriverVirtualMachine -ComputerSystem $systemInfo) {
        Write-Information 'This script cannot be run on a virtual machine.'
        return 3
    }

    Write-Information 'Running on a physical machine.'

    try {
        $devconPath = Get-DisplayDriverDevConPath -ScriptRoot $ScriptRoot
        Write-Information "Found devcon.exe at $devconPath"
    }
    catch {
        Write-Information $_.Exception.Message
        return 2
    }

    try {
        Write-Information 'Querying display devices with devcon.exe...'
        $listResult = Invoke-DisplayDriverDevCon -DevConPath $devconPath -ArgumentList @('listclass', 'display')

        if (-not $listResult.Output) {
            throw 'devcon.exe returned no output when listing display devices.'
        }

        Write-Information 'Successfully retrieved display device list.'
    }
    catch {
        Write-Error "Failed to query display devices: $($_.Exception.Message)"
        return 4
    }

    try {
        foreach ($line in $listResult.Output) {
            $trimmedLine = "$line".Trim()
            $hardwareID = Get-DisplayHardwareIdFromLine -Line $trimmedLine

            if ($null -ne $hardwareID) {
                if ($PSCmdlet.ShouldProcess($hardwareID, 'Remove display driver')) {
                    Write-Information "Removing driver package: $hardwareID"

                    $removeResult = Invoke-DisplayDriverDevCon -DevConPath $devconPath -ArgumentList @('remove', $hardwareID)
                    foreach ($message in $removeResult.Output) {
                        Write-Information "$message"
                    }

                    if ($removeResult.ExitCode -ne 0) {
                        throw "devcon.exe failed to remove $hardwareID (exit code $($removeResult.ExitCode))."
                    }
                }
            }
            else {
                Write-Information "Info: Skipping line (no valid hardware ID pattern found): '$trimmedLine'"
            }
        }

        Write-Information 'Script completed successfully.'
        return 0
    }
    catch {
        Write-Error "Script failed with error: $($_.Exception.Message)"
        return 1
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    exit (Invoke-UninstallDisplayDrivers -ScriptRoot $PSScriptRoot @PSBoundParameters -InformationAction Continue)
}
