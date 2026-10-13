# Windows Server 2025 Active Directory Home Lab

## Project Overview

This project documents the design, deployment, configuration, and security validation of a virtualized Windows Server 2025 Active Directory environment using Oracle VirtualBox.

The lab simulates a small enterprise network with centralized identity management, domain authentication, organizational units, security groups, Group Policy, DNS, departmental file sharing, and role-based access controls.

### Key Accomplishments

- Deployed Windows Server 2025 as a domain controller (DC01) for `adlab.test`.
- Installed and configured Active Directory Domain Services (AD DS) and DNS.
- Created 200 Active Directory user accounts across four departments using PowerShell.
- Organized IT, HR, Finance, and Sales into departmental organizational units and security groups.
- Deployed a Windows 11 Pro client and joined it to the domain.
- Configured and verified a workstation security baseline Group Policy.
- Implemented departmental SMB shares with NTFS and share-level permissions.
- Validated authorized access and denied unauthorized cross-department access.
- Troubleshot DNS registration on a multi-homed domain controller.
- Verified domain-controller and DNS health using DCDIAG and PowerShell.
- Created VirtualBox baseline snapshots to preserve the completed environment.

### Technologies Used

Windows Server 2025 | Windows 11 Pro | Active Directory Domain Services | DNS | Group Policy | PowerShell | SMB | NTFS | Oracle VirtualBox

  
## Network Architecture

The lab uses Oracle VirtualBox to host a Windows Server 2025 domain controller and a Windows 11 Pro domain-joined workstation. Both virtual machines use two network adapters: NAT for outbound connectivity and a dedicated Host-Only network for Active Directory communication.

### Network Configuration

| Component | Hostname | IP Address | Purpose |
|---|---|---|---|
| Domain Controller | DC01 | 192.168.56.10 | Active Directory Domain Services and DNS |
| Windows 11 Client | WIN11-CLIENT01 | 192.168.56.20 | Domain-joined workstation and security testing |
| Active Directory Domain | adlab.test | N/A | Centralized identity and authentication |
| Host-Only Network | AD-LAB | 192.168.56.0/24 | Internal lab communication |
| NAT Adapter | VirtualBox NAT | DHCP | Outbound network connectivity |

### DNS Configuration

- DC01 provides DNS services for the `adlab.test` Active Directory domain.
- WIN11-CLIENT01 uses `192.168.56.10` as its DNS server.
- The domain controller's Host-Only adapter uses the static IP address `192.168.56.10`.
- DNS registration was disabled on DC01's NAT adapter to prevent its NAT address from being advertised to domain clients.
- Verified LDAP SRV records, DNS name resolution, dynamic updates, and domain-controller health using PowerShell and DCDIAG.

### Virtualization Configuration

- **Hypervisor:** Oracle VirtualBox
- **Host operating system:** Windows 11
- **Server operating system:** Windows Server 2025 Standard Evaluation
- **Client operating system:** Windows 11 Pro
- **Network adapters:** NAT and Host-Only (AD-LAB)
- **Recovery:** Powered-off baseline snapshots for both virtual machines


## Active Directory Organizational Structure

Created a departmental Active Directory structure to simulate enterprise identity and access management. User accounts were provisioned using PowerShell and assigned to security groups based on their departments.

### Organizational Units and Security Groups

| Organizational Unit | Security Group | User Accounts |
|---|---|---:|
| IT | SG-IT | 50 |
| HR | SG-HR | 50 |
| Finance | SG-Finance | 50 |
| Sales | SG-Sales | 50 |
| **Total** | **4 Security Groups** | **200** |

### Directory Hierarchy

```text
adlab.test
└── ADLAB
    ├── IT
    ├── HR
    ├── Finance
    └── Sales
```

### Identity Management and Automation

- Created 200 user accounts through PowerShell-based bulk provisioning.
- Organized accounts into four departmental organizational units.
- Configured security groups to support role-based access control (RBAC).
- Assigned users to their respective departmental security groups.
- Verified group membership using PowerShell, confirming 50 users per group.
- Used departmental groups to control access to SMB shares and NTFS-protected folders.
  

  
## Group Policy and Security Configuration

### Group Policy Management

Configured and verified centralized Group Policy processing for the Windows 11 domain-joined workstation.

- Created `GPO-Workstation-Security-Baseline` for workstation security management.
- Verified application of the workstation security baseline GPO and Default Domain Policy.
- Confirmed Windows Defender Antivirus and Windows Firewall were enabled on the client.
- Used Group Policy verification to confirm the workstation received domain-managed policies.

### Departmental File Share Security

Created four departmental SMB shares on DC01 under `C:\LabShares` and configured share-level and NTFS permissions.

| Department | Authorized Security Group | Share Permission | NTFS Permission |
|---|---|---|---|
| IT | SG-IT | Change | Modify |
| HR | SG-HR | Change | Modify |
| Finance | SG-Finance | Change | Modify |
| Sales | SG-Sales | Change | Modify |

Domain Administrators retain Full Control at the share level, while SYSTEM and local Administrators retain Full Control at the NTFS level.

### Role-Based Access Control (RBAC) Validation

Tested domain user accounts from each department using the Windows 11 client.

- Verified authorized users could create and modify files in their departmental shares.
- Verified users were denied access to other departments' protected shares.
- Validated all four departments: IT, HR, Finance, and Sales.
- Audited SMB share permissions, NTFS access control lists, and Active Directory security group memberships using PowerShell.

**Result:** Departmental access testing confirmed that authorized operations succeeded and cross-department access attempts were denied for the tested accounts.


  
## Troubleshooting and Problem Resolution

### Issue: Multi-Homed Domain Controller DNS Registration

**Problem:** During DNS validation, DC01 registered both its internal Host-Only address (`192.168.56.10`) and its VirtualBox NAT address (`10.0.2.15`) in Active Directory DNS.

**Risk:** Domain clients could receive the NAT address, which is not the intended address for communication between the lab virtual machines.

**Investigation and resolution:**

1. Identified both network adapters and their assigned IPv4 addresses using PowerShell.
2. Disabled DNS address registration on DC01's NAT interface (`Ethernet 2`).
3. Recovered the virtual machine using a graceful ACPI shutdown after it became unresponsive while applying the configuration change.
4. Removed only the unwanted `10.0.2.15` DNS A record, preserving `192.168.56.10`.
5. Verified LDAP SRV records and confirmed that DC01 resolved to the correct internal IPv4 address.
6. Re-ran domain-controller and DNS diagnostics to validate the corrected configuration.

### Validation Results

| Validation | Result |
|---|---|
| Domain controller connectivity | PASS |
| Advertising, Services, SYSVOL, and NetLogons | PASS |
| LDAP SRV record lookup | PASS |
| DNS authentication | PASS |
| DNS dynamic update | PASS |
| DNS record registration | PASS |
| DNS diagnostic overall | PASS with Basic configuration warning |

**Known warning:** DCDIAG flagged the NAT adapter's DHCP-assigned IP address as a potential configuration issue. The lab intentionally uses NAT with DHCP for outbound connectivity. The warning was documented rather than misrepresented as a clean result.

**Outcome:** The unwanted NAT A record remained absent during follow-up verification, and the requested domain-controller health and DNS tests passed.


  
## Project Outcomes and Lessons Learned

### Project Outcomes

- Deployed and validated a functional Windows Server 2025 Active Directory lab with a domain-joined Windows 11 workstation.
- Automated the provisioning of 200 domain user accounts across four departments.
- Implemented security groups, SMB share permissions, and NTFS permissions to enforce departmental access restrictions.
- Verified centralized Group Policy processing and endpoint security status.
- Conducted positive and negative access-control tests to validate departmental permissions.
- Diagnosed and corrected an unwanted NAT IP address registration in Active Directory DNS.
- Preserved the tested environment using VirtualBox baseline snapshots.

### Lessons Learned

1. **Identity and access management:** Organizational units provide administrative structure, while security group membership can be used to grant role-based access to resources.
2. **Defense in depth:** SMB share permissions and NTFS access control lists must work together to enforce appropriate access restrictions.
3. **Validation matters:** Successful configuration is not sufficient without verifying access, policy application, and service health.
4. **DNS is critical to Active Directory:** Incorrect DNS registration on a multi-homed domain controller can cause domain discovery and connectivity problems.
5. **Troubleshooting requires controlled changes:** Targeted configuration updates, read-only verification commands, and graceful recovery procedures reduce unnecessary risk.
6. **Recovery planning:** VirtualBox snapshots provide useful lab rollback points but are not substitutes for independent backups.

### Skills Demonstrated

Active Directory Administration | Windows Server Administration | PowerShell Automation | DNS Troubleshooting | Group Policy | Identity and Access Management | RBAC | SMB and NTFS Permissions | Security Testing | Virtualization | Technical Documentation

## Supporting Evidence

The following directories contain implementation screenshots,
configuration verification, and security testing evidence:

| Evidence Category | Documentation |
|---|---|
| Windows Server 2025 / DC01 | [DC01 Deployment Screenshots](screenshots/01-DC01-Windows-Server-2025/) |
| Windows 11 Client | [Windows 11 Client Screenshots](screenshots/02-WIN11-CLIENT01/) |
| Security Validation and Testing | [Validation Screenshots](screenshots/03-Validation-and-Testing/) |

## Project Status

**Baseline v1.0 completed:** Core Active Directory deployment,
domain integration, departmental access controls, DNS validation,
and recovery snapshots.

## Future Enhancements

- Implement centralized security monitoring and event log analysis.
- Configure advanced Windows auditing policies.
- Explore endpoint detection and security event investigation.
- Develop additional PowerShell administration scripts.
- Expand the lab with cybersecurity incident response exercises.
