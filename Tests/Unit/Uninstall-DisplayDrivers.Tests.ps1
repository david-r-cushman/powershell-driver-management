BeforeAll {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath '..\..\src\Public\Uninstall-DisplayDrivers.ps1'
    . $scriptPath
}

Describe 'Test-DisplayDriverVirtualMachine' {
    It 'returns true when the manufacturer matches a known VM platform' {
        $computerSystem = [pscustomobject]@{
            Manufacturer = 'VMware, Inc.'
            Model        = 'Precision 3680'
        }

        Test-DisplayDriverVirtualMachine -ComputerSystem $computerSystem | Should -BeTrue
    }

    It 'returns false for a physical workstation' {
        $computerSystem = [pscustomobject]@{
            Manufacturer = 'Dell Inc.'
            Model        = 'Precision 3680'
        }

        Test-DisplayDriverVirtualMachine -ComputerSystem $computerSystem | Should -BeFalse
    }
}

Describe 'Get-DisplayHardwareIdFromLine' {
    It 'extracts a PCI hardware ID from a devcon listclass line' {
        $line = 'PCI\VEN_8086&DEV_3E98&SUBSYS_09611028&REV_02\3&11583659&0&10: Intel(R) UHD Graphics 630'

        Get-DisplayHardwareIdFromLine -Line $line | Should -Be 'PCI\VEN_8086&DEV_3E98&SUBSYS_09611028&REV_02'
    }

    It 'returns null for a non-device line' {
        Get-DisplayHardwareIdFromLine -Line '1 matching device(s) found.' | Should -Be $null
    }
}

Describe 'Invoke-UninstallDisplayDrivers' {
    BeforeEach {
        Mock Test-DisplayDriverAdministrativeContext { $true }
        Mock Get-DisplayDriverComputerSystem {
            [pscustomobject]@{
                Manufacturer = 'Dell Inc.'
                Model        = 'Precision 3680'
            }
        }
    }

    It 'returns exit code 5 when not running in an administrative context' {
        Mock Test-DisplayDriverAdministrativeContext { $false }

        $result = Invoke-UninstallDisplayDrivers -ScriptRoot 'C:\Temp'

        $result | Should -Be 5
        Should -Invoke Get-DisplayDriverComputerSystem -Times 0
    }

    It 'returns exit code 3 when the script is run on a virtual machine' {
        Mock Get-DisplayDriverComputerSystem {
            [pscustomobject]@{
                Manufacturer = 'VMware, Inc.'
                Model        = 'VMware Virtual Platform'
            }
        }
        Mock Get-DisplayDriverDevConPath { 'C:\Temp\devcon.exe' }

        $result = Invoke-UninstallDisplayDrivers -ScriptRoot 'C:\Temp'

        $result | Should -Be 3
        Should -Invoke Get-DisplayDriverDevConPath -Times 0
    }

    It 'returns exit code 2 when devcon.exe is missing' {
        Mock Get-DisplayDriverDevConPath {
            throw [System.IO.FileNotFoundException]::new('Error: devcon.exe not found in script directory (C:\Temp).')
        }

        $result = Invoke-UninstallDisplayDrivers -ScriptRoot 'C:\Temp'

        $result | Should -Be 2
    }

    It 'returns exit code 4 when listing display devices fails' {
        Mock Get-DisplayDriverDevConPath { 'C:\Temp\devcon.exe' }
        Mock Invoke-DisplayDriverDevCon -ParameterFilter { $ArgumentList[0] -eq 'listclass' } {
            throw 'devcon.exe execution failed.'
        }

        $result = Invoke-UninstallDisplayDrivers -ScriptRoot 'C:\Temp' -ErrorAction SilentlyContinue

        $result | Should -Be 4
    }

    It 'returns exit code 0 and does not remove drivers under WhatIf' {
        Mock Get-DisplayDriverDevConPath { 'C:\Temp\devcon.exe' }
        Mock Invoke-DisplayDriverDevCon -ParameterFilter { $ArgumentList[0] -eq 'listclass' } {
            [pscustomobject]@{
                Output   = @(
                    'PCI\VEN_8086&DEV_3E98&SUBSYS_09611028&REV_02\3&11583659&0&10: Intel(R) UHD Graphics 630',
                    '1 matching device(s) found.'
                )
                ExitCode = 0
            }
        }

        $result = Invoke-UninstallDisplayDrivers -ScriptRoot 'C:\Temp' -WhatIf

        $result | Should -Be 0
        Should -Invoke Invoke-DisplayDriverDevCon -ParameterFilter { $ArgumentList[0] -eq 'remove' } -Times 0
    }

    It 'returns exit code 1 when devcon removal fails' {
        Mock Get-DisplayDriverDevConPath { 'C:\Temp\devcon.exe' }
        Mock Invoke-DisplayDriverDevCon -ParameterFilter { $ArgumentList[0] -eq 'listclass' } {
            [pscustomobject]@{
                Output   = @('PCI\VEN_8086&DEV_3E98&SUBSYS_09611028&REV_02\3&11583659&0&10: Intel(R) UHD Graphics 630')
                ExitCode = 0
            }
        }
        Mock Invoke-DisplayDriverDevCon -ParameterFilter { $ArgumentList[0] -eq 'remove' } {
            [pscustomobject]@{
                Output   = @('Remove failed.')
                ExitCode = 1
            }
        }

        $result = Invoke-UninstallDisplayDrivers -ScriptRoot 'C:\Temp' -Confirm:$false -ErrorAction SilentlyContinue

        $result | Should -Be 1
        Should -Invoke Invoke-DisplayDriverDevCon -ParameterFilter { $ArgumentList[0] -eq 'remove' } -Times 1
    }

    It 'returns exit code 0 when driver removal succeeds' {
        Mock Get-DisplayDriverDevConPath { 'C:\Temp\devcon.exe' }
        Mock Invoke-DisplayDriverDevCon -ParameterFilter { $ArgumentList[0] -eq 'listclass' } {
            [pscustomobject]@{
                Output   = @('PCI\VEN_8086&DEV_3E98&SUBSYS_09611028&REV_02\3&11583659&0&10: Intel(R) UHD Graphics 630')
                ExitCode = 0
            }
        }
        Mock Invoke-DisplayDriverDevCon -ParameterFilter { $ArgumentList[0] -eq 'remove' } {
            [pscustomobject]@{
                Output   = @('1 device(s) removed.')
                ExitCode = 0
            }
        }

        $result = Invoke-UninstallDisplayDrivers -ScriptRoot 'C:\Temp' -Confirm:$false

        $result | Should -Be 0
        Should -Invoke Invoke-DisplayDriverDevCon -ParameterFilter { $ArgumentList[0] -eq 'remove' } -Times 1
    }
}
