<#
.SYNOPSIS
    Read-only audit of departmental SMB shares in the ADLAB home lab.
.DESCRIPTION
    Audits the IT, HR, Finance and Sales SMB shares on DC01.
    Reports share paths and share-level access entries, then checks for
    the expected departmental Change and Domain Admins Full permissions.

    Adapted from Get-SmbShare and Get-SmbShareAccess commands used in the lab.
    This reconstructed script has not been independently executed or tested.
.NOTES
    Windows Server 2025 Active Directory Home Lab (adlab.test)
    Run on DC01 with permission to enumerate local SMB shares.
    READ-ONLY: No changes to shares or access control lists.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$Departments = @('IT', 'HR', 'Finance', 'Sales')
$ExpectedAdmin = 'ADLAB\Domain Admins'

$Results = foreach ($Department in $Departments) {
    $ExpectedGroup = "ADLAB\SG-$Department"
    $ExpectedPath = "C:\LabShares\$Department"

    try {
        $Share = Get-SmbShare -Name $Department -ErrorAction Stop
        $Access = @(Get-SmbShareAccess -Name $Department -ErrorAction Stop)

        $DepartmentRule = @($Access | Where-Object {
            $_.AccountName -eq $ExpectedGroup -and
            $_.AccessControlType -eq 'Allow' -and
            $_.AccessRight -eq 'Change'
        })

        $AdminRule = @($Access | Where-Object {
            $_.AccountName -eq $ExpectedAdmin -and
            $_.AccessControlType -eq 'Allow' -and
            $_.AccessRight -eq 'Full'
        })

        $UnexpectedEntries = @($Access | Where-Object {
            $_.AccountName -notin @($ExpectedGroup, $ExpectedAdmin)
        })

        [PSCustomObject]@{
            Department             = $Department
            ShareName              = $Share.Name
            Path                   = $Share.Path
            PathMatchesBaseline    = ($Share.Path -ieq $ExpectedPath)
            GroupChangeAccess      = ($DepartmentRule.Count -gt 0)
            DomainAdminsFullAccess = ($AdminRule.Count -gt 0)
            UnexpectedEntryCount   = $UnexpectedEntries.Count
            Error                  = ''
        }

        Write-Host "`n[$Department] Share-level permissions" -ForegroundColor Cyan
        $Access | Select-Object Name, AccountName, AccessControlType, AccessRight |
            Format-Table -AutoSize

        if ($UnexpectedEntries.Count -gt 0) {
            Write-Warning "$Department has additional share permission entries; review them manually."
        }
    }
    catch {
        [PSCustomObject]@{
            Department             = $Department
            ShareName              = $Department
            Path                   = ''
            PathMatchesBaseline    = $false
            GroupChangeAccess      = $false
            DomainAdminsFullAccess = $false
            UnexpectedEntryCount   = $null
            Error                  = $_.Exception.Message
        }
    }
}

Write-Host "`nADLAB SMB SHARE AUDIT SUMMARY" -ForegroundColor Cyan
$Results | Format-Table -AutoSize

$Issues = @($Results | Where-Object {
    $_.Error -or
    -not $_.PathMatchesBaseline -or
    -not $_.GroupChangeAccess -or
    -not $_.DomainAdminsFullAccess -or
    $_.UnexpectedEntryCount -gt 0
})

if ($Issues.Count -eq 0) {
    Write-Host 'All four shares match the checked share-level baseline.' -ForegroundColor Green
}
else {
    Write-Warning "$($Issues.Count) share(s) require review."
}

Write-Host 'This audit does not verify NTFS permissions or effective user access.'
