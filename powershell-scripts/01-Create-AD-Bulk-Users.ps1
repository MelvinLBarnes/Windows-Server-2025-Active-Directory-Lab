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
    LAB ONLY. Not idempotent: running it again creates additional users.
    Review the target OUs and test in a disposable lab before execution.
#>

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

# The original script used a shared, hardcoded lab password.
# Prompting securely is the only behavioral security change in this version.
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
