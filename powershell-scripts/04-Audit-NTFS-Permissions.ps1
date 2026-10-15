<#
.SYNOPSIS
    Read-only NTFS permissions audit for ADLAB departmental shares.
.DESCRIPTION
    Reports NTFS access control entries for the IT, HR, Finance, and Sales
    departmental folders. Checks whether each department's AD security group
    has an Allow/Modify rule and whether the folder protects its ACL from
    inherited permissions. Also flags broad access principals for review.

    Reconstructed from Get-Acl verification commands used in the
    Windows Server 2025 Active Directory home lab. This script does not
    change permissions or create folders.
.NOTES
    Lab: adlab.test | Domain controller: DC01
    Educational audit only. Inspect the raw rules before drawing conclusions
    about effective permissions; deny entries and nested groups can affect access.
#>

[CmdletBinding()]
param(
    [string]$ShareRoot = 'C:\LabShares'
)

$departments = @('IT', 'HR', 'Finance', 'Sales')

foreach ($department in $departments) {
    $folder = Join-Path -Path $ShareRoot -ChildPath $department
    $expectedGroup = "ADLAB\SG-$department"

    Write-Host "`n=== $department : $folder ===" -ForegroundColor Cyan

    if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
        Write-Warning "Folder not found: $folder"
        continue
    }

    try {
        $acl = Get-Acl -LiteralPath $folder -ErrorAction Stop
    }
    catch {
        Write-Warning "Unable to read ACL for ${folder}: $($_.Exception.Message)"
        continue
    }

    $rules = @($acl.Access)
    $matchingRules = @($rules | Where-Object {
        $_.IdentityReference.Value -ieq $expectedGroup -and
        $_.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Allow -and
        (($_.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Modify) -eq
         [System.Security.AccessControl.FileSystemRights]::Modify)
    })

    $broadPrincipals = @($rules | Where-Object {
        $_.IdentityReference.Value -in @('Everyone', 'BUILTIN\Users', 'NT AUTHORITY\Authenticated Users', 'ADLAB\Domain Users') -and
        $_.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Allow
    })

    [PSCustomObject]@{
        Department           = $department
        Folder               = $folder
        InheritanceDisabled  = [bool]$acl.AreAccessRulesProtected
        ExpectedGroup        = $expectedGroup
        ModifyRuleFound      = ($matchingRules.Count -gt 0)
        BroadAllowRuleCount  = $broadPrincipals.Count
        TotalAccessRules     = $rules.Count
    } | Format-List

    $rules |
        Select-Object IdentityReference, FileSystemRights, AccessControlType, IsInherited, InheritanceFlags, PropagationFlags |
        Format-Table -AutoSize -Wrap

    if ($broadPrincipals.Count -gt 0) {
        Write-Warning "Broad Allow rules found for $department. Review the entries above."
    }
}

Write-Host "`nAudit finished. No permissions were changed." -ForegroundColor Green
