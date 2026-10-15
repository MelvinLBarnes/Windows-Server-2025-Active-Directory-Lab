<#
.SYNOPSIS
    Assigns departmental Active Directory users to matching security groups.
.DESCRIPTION
    Reconstructed and safety-enhanced version of the group membership
    assignment used in the Windows Server 2025 ADLAB home lab.

    Maps users in the IT, HR, Finance, and Sales OUs to SG-IT, SG-HR,
    SG-Finance, and SG-Sales respectively. Only missing memberships are
    proposed. No changes are made unless -Apply is explicitly supplied.
.EXAMPLE
    .\02-Assign-Department-Groups.ps1
    Preview required group membership changes.
.EXAMPLE
    .\02-Assign-Department-Groups.ps1 -Apply
    Apply required changes after reviewing the preview.
.NOTES
    Lab domain: adlab.test; domain controller: DC01.
    Requires the ActiveDirectory module, network access to the lab domain,
    and appropriate permissions to update group membership.
    Educational lab use. Do not run against the completed lab simply to
    document it. This published version has not been independently tested.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
Import-Module ActiveDirectory -ErrorAction Stop

$Departments = [ordered]@{
    IT      = @{ OU = 'OU=IT,OU=ADLAB,DC=adlab,DC=test'; Group = 'SG-IT' }
    HR      = @{ OU = 'OU=HR,OU=ADLAB,DC=adlab,DC=test'; Group = 'SG-HR' }
    Finance = @{ OU = 'OU=Finance,OU=ADLAB,DC=adlab,DC=test'; Group = 'SG-Finance' }
    Sales   = @{ OU = 'OU=Sales,OU=ADLAB,DC=adlab,DC=test'; Group = 'SG-Sales' }
}

Write-Host 'ADLAB departmental security group membership audit' -ForegroundColor Cyan

foreach ($Department in $Departments.Keys) {
    $Configuration = $Departments[$Department]
    $OUPath = $Configuration.OU
    $GroupName = $Configuration.Group

    # Fail safely if expected directory objects do not exist.
    Get-ADOrganizationalUnit -Identity $OUPath | Out-Null
    $Group = Get-ADGroup -Identity $GroupName

    $Users = @(Get-ADUser -Filter * -SearchBase $OUPath -SearchScope OneLevel)
    $ExistingMemberDNs = @{}
    foreach ($Member in @(Get-ADGroupMember -Identity $Group.DistinguishedName)) {
        $ExistingMemberDNs[$Member.DistinguishedName] = $true
    }

    $MissingUsers = @($Users | Where-Object {
        -not $ExistingMemberDNs.ContainsKey($_.DistinguishedName)
    })

    [PSCustomObject]@{
        Department          = $Department
        Group               = $GroupName
        UsersInOU           = $Users.Count
        MissingMemberships  = $MissingUsers.Count
        Mode                = $(if ($Apply) { 'Apply requested' } else { 'Preview only' })
    } | Format-Table -AutoSize

    if ($MissingUsers.Count -eq 0) {
        Write-Host "[$Department] No missing memberships." -ForegroundColor Green
        continue
    }

    if (-not $Apply) {
        Write-Host "[$Department] PREVIEW: $($MissingUsers.Count) users would be added to $GroupName." -ForegroundColor Yellow
        continue
    }

    if ($PSCmdlet.ShouldProcess($GroupName, "Add $($MissingUsers.Count) missing departmental users")) {
        Add-ADGroupMember -Identity $Group.DistinguishedName -Members $MissingUsers -ErrorAction Stop
        Write-Host "[$Department] Added $($MissingUsers.Count) users to $GroupName." -ForegroundColor Green
    }
}

Write-Host 'Departmental group membership review complete.' -ForegroundColor Cyan
