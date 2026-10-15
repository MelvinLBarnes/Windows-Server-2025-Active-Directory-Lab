<#
.SYNOPSIS
    Read-only domain controller and DNS health checks for the ADLAB home lab.
.DESCRIPTION
    Reconstructed and documented from administrative commands used on DC01.
    Checks domain controller health, LDAP service discovery, server A records,
    and network-interface DNS registration settings. Makes no changes.
.NOTES
    Lab domain: adlab.test
    Domain controller: DC01
    This portfolio reconstruction has not been independently executed.
    Run in a Windows PowerShell session on DC01 with appropriate permissions.
#>

[CmdletBinding()]
param(
    [string]$DomainName = 'adlab.test',
    [string]$DomainController = 'DC01'
)

$ErrorActionPreference = 'Stop'
$DcFqdn = "$DomainController.$DomainName"
$SrvRecordName = "_ldap._tcp.dc._msdcs.$DomainName"

Write-Host "=== ADLAB Domain Controller / DNS Health Audit ===" -ForegroundColor Cyan
Write-Host "Domain: $DomainName | DC: $DcFqdn"

# 1. DCDIAG: diagnostic command only, no directory modifications.
Write-Host "`n[1/5] Domain controller diagnostic tests" -ForegroundColor Cyan
if (-not (Get-Command dcdiag.exe -ErrorAction SilentlyContinue)) {
    Write-Warning 'dcdiag.exe is unavailable on this computer.'
} else {
    & dcdiag.exe /s:$DomainController /test:Advertising /test:Services /test:SysVolCheck /test:NetLogons
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "DCDIAG reported a nonzero exit code: $LASTEXITCODE"
    }
}

# 2. A records: the DC should resolve to its intended Host-Only IP.
Write-Host "`n[2/5] DNS A-record lookup" -ForegroundColor Cyan
try {
    Resolve-DnsName -Name $DcFqdn -Type A |
        Select-Object Name, Type, IPAddress |
        Format-Table -AutoSize
} catch {
    Write-Warning "A-record lookup failed: $($_.Exception.Message)"
}

# 3. AD LDAP service locator (SRV) record.
Write-Host "`n[3/5] Domain controller LDAP SRV lookup" -ForegroundColor Cyan
try {
    Resolve-DnsName -Name $SrvRecordName -Type SRV |
        Where-Object { $_.Type -eq 'SRV' } |
        Select-Object Name, NameTarget, Port, Priority, Weight |
        Format-Table -AutoSize
} catch {
    Write-Warning "LDAP SRV lookup failed: $($_.Exception.Message)"
}

# 4. Inspect DNS-zone A records, if DNS Server tools are installed.
Write-Host "`n[4/5] Authoritative DNS zone A records" -ForegroundColor Cyan
try {
    Import-Module DnsServer -ErrorAction Stop
    Get-DnsServerResourceRecord -ZoneName $DomainName -Name $DomainController -RRType A -ComputerName $DomainController |
        Select-Object HostName, @{Name='IPv4Address'; Expression={$_.RecordData.IPv4Address.IPAddressToString}} |
        Format-Table -AutoSize
} catch {
    Write-Warning "Could not read DNS server records: $($_.Exception.Message)"
}

# 5. Review interface registration settings. Intended host-only=True, NAT=False.
Write-Host "`n[5/5] DNS client interface registration" -ForegroundColor Cyan
try {
    Get-DnsClient |
        Where-Object { $_.InterfaceAlias -in @('Ethernet', 'Ethernet 2') } |
        Select-Object InterfaceAlias, RegisterThisConnectionsAddress |
        Format-Table -AutoSize
} catch {
    Write-Warning "DNS interface inspection failed: $($_.Exception.Message)"
}

Write-Host "`nRead-only audit finished. Review results and warnings manually." -ForegroundColor Green
