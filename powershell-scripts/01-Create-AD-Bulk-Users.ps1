<#
.SYNOPSIS
    Creates fictional Active Directory users for the ADLAB training environment.
.DESCRIPTION
    Reconstructed from the lab's provisioning commands and PowerShell history.
    Creates 50 NEW users in each of four departmental organizational units.
    Does not assign users to security groups; this was performed separately.
    No plaintext passwords are embedded in this file.
.NOTES
    Lab domain: adlab.test
    Domain controller: DC01
    LAB ONLY. The -Apply parameter is required to create users.
    Not idempotent: executing with -Apply can create additional accounts.
    Review the target OUs and test in a disposable lab before execution.
#>


[CmdletBinding()]
param(
    [switch]$Apply
)


Import-Module ActiveDirectory -ErrorAction Stop

$USERS_PER_DEPARTMENT = 50
$departments = @{
    'IT'      = 'OU=IT,OU=ADLAB,DC=adlab,DC=test'
    'HR'      = 'OU=HR,OU=ADLAB,DC=adlab,DC=test'
    'Finance' = 'OU=Finance,OU=ADLAB,DC=adlab,DC=test'
    'Sales'   = 'OU=Sales,OU=ADLAB,DC=adlab,DC=test'
}

function Generate-RandomName {
    $consonants = @('b','c','d','f','g','h','j','k','l','m','n','p','q','r','s','t','v','w','x','z')
    $vowels = @('a','e','i','o','u','y')

    $name = ''
    $length = Get-Random -Minimum 3 -Maximum 7

    for ($i = 0; $i -lt $length; $i++) {
        if ($i % 2 -eq 0) {
            $name += Get-Random -InputObject $consonants
        }
        else {
            $name += Get-Random -InputObject $vowels
        }
    }
    return $name
}


# Safety check: preview by default.
if (-not $Apply) {
    Write-Host "PREVIEW MODE - No accounts will be created." -ForegroundColor Yellow

    foreach ($department in $departments.Keys) {
        Write-Host "Would attempt to create $USERS_PER_DEPARTMENT users in $department"
    }

    Write-Host "To authorize creation, run this script with -Apply." -ForegroundColor Cyan
    return
}


# Credentials are entered securely instead of being hardcoded.
# Account creation requires the explicit -Apply parameter.

$password = Read-Host 'Enter a temporary password for NEW lab accounts' -AsSecureString

foreach ($department in $departments.Keys) {
    $created = 0
    $attempts = 0

    while ($created -lt $USERS_PER_DEPARTMENT -and $attempts -lt 1000) {
        $attempts++
        $firstName = Generate-RandomName
        $lastName = Generate-RandomName
        $username = "$firstName.$lastName"

        if (Get-ADUser -Filter "SamAccountName -eq '$username'" -ErrorAction Stop) {
            continue
        }

        try {
            New-ADUser `
                -Name $username `
                -GivenName $firstName `
                -Surname $lastName `
                -DisplayName $username `
                -SamAccountName $username `
                -UserPrincipalName "$username@adlab.test" `
                -AccountPassword $password `
                -Path $departments[$department] `
                -Enabled $true `
                -ErrorAction Stop

            $created++
            Write-Host "SUCCESS [$department]: $username" -ForegroundColor Green
        }
        catch {
            Write-Warning "FAILED [$department]: $username - $($_.Exception.Message)"
        }
    }

    Write-Host "$department : $created accounts created" -ForegroundColor Cyan
}
