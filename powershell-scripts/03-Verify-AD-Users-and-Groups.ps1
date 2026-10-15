<#
.SYNOPSIS
    Read-only Active Directory user and departmental group membership audit.
.DESCRIPTION
    Reconstructed from commands used in the Windows Server 2025 ADLAB lab.
    Reports direct OU user counts, direct user group-membership counts,
    and users whose distinguished names do not match their group department.
    This script does not create, modify, or delete directory objects.
.NOTES
    Domain: adlab.test
    Lab-only example; requires the ActiveDirectory module and AD read access.
    Validate output in your own environment before relying on it.
#>

#Requires -Modules ActiveDirectory

$ErrorActionPreference = 'Stop'
$Departments = @('IT', 'HR', 'Finance', 'Sales')
$BaseDN = 'OU=ADLAB,DC=adlab,DC=test'
$ExpectedUsersPerDepartment = 50

try {
    $Report = foreach ($Department in $Departments) {
        $OU = "OU=$Department,$BaseDN"
        $GroupName = "SG-$Department"

        # Direct OU user population (not recursive).
        $OUUsers = @(Get-ADUser -Filter * -SearchBase $OU -SearchScope OneLevel)

        # Direct user members only; non-user group members are excluded.
        $Members = @(Get-ADGroupMember -Identity $GroupName |
            Where-Object { $_.objectClass -eq 'user' })

        # Flag any direct user member whose DN does not belong to this department's OU.
        $Incorrect = @($Members | Where-Object {
            $_.DistinguishedName -notlike "*,$OU"
        })

        [PSCustomObject]@{
            Department       = $Department
            OrganizationalUnit = $OU
            SecurityGroup    = $GroupName
            OUUserCount      = $OUUsers.Count
            GroupUserCount   = $Members.Count
            IncorrectMembers = $Incorrect.Count
            MeetsTarget      = ($OUUsers.Count -eq $ExpectedUsersPerDepartment -and
                                $Members.Count -eq $ExpectedUsersPerDepartment -and
                                $Incorrect.Count -eq 0)
        }
    }

    Write-Host "`nADLAB Departmental Identity Audit" -ForegroundColor Cyan
    $Report | Format-Table Department, SecurityGroup, OUUserCount, GroupUserCount, IncorrectMembers, MeetsTarget -AutoSize

    $TotalOUUsers = ($Report | Measure-Object -Property OUUserCount -Sum).Sum
    $TotalGroupUsers = ($Report | Measure-Object -Property GroupUserCount -Sum).Sum
    Write-Host "Total users in departmental OUs: $TotalOUUsers"
    Write-Host "Total direct user group memberships: $TotalGroupUsers"

    if (@($Report | Where-Object { -not $_.MeetsTarget }).Count -gt 0) {
        Write-Warning 'One or more departmental counts or membership checks differ from the lab baseline.'
    }
    else {
        Write-Host 'All four departments match the 50-user baseline and OU membership checks.' -ForegroundColor Green
    }
}
catch {
    Write-Error "Audit could not complete: $($_.Exception.Message)"
    exit 1
}
