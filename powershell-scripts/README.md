# Active Directory PowerShell Automation

This directory contains PowerShell scripts used or reconstructed from the Windows Server 2025 Active Directory Home Lab.

## Available Scripts

| Script | Purpose |
|---|---|
| [01-Create-AD-Bulk-Users.ps1](01-Create-AD-Bulk-Users.ps1) | Reconstructed and sanitized PowerShell script for provisioning 200 Active Directory users across four departments. |
| [02-Assign-Department-Groups.ps1](02-Assign-Department-Groups.ps1) | Assigns departmental users to the appropriate Active Directory security groups, with membership checks and preview-only safeguards. |
| [03-Verify-AD-Users-and-Groups.ps1](03-Verify-AD-Users-and-Groups.ps1) | Read-only audit of 200 departmental users, security group memberships, and incorrect OU assignments. |
| [04-Audit-NTFS-Permissions.ps1](04-Audit-NTFS-Permissions.ps1) | Read-only audit of departmental NTFS permissions, inheritance settings, and access control entries for IT, HR, Finance, and Sales. |
| [05-Audit-SMB-Shares.ps1](05-Audit-SMB-Shares.ps1) | Read-only audit of departmental SMB share paths, security group permissions, Domain Admins access, and unexpected access entries. |


## Lab Environment

- **Domain:** `adlab.test`
- **Domain Controller:** DC01 — Windows Server 2025
- **Departmental OUs:** IT, HR, Finance, Sales
- **Total provisioned accounts:** 200

## Security and Usage Notes

Scripts are provided for educational demonstration and technical documentation. Credentials have been removed or replaced with secure input methods.

The PowerShell scripts in this repository were reconstructed and enhanced from commands used during the original Windows Server 2025 Active Directory lab. They preserve the administrative workflows while incorporating improved documentation, security practices, and validation logic. The reconstructed versions have not been independently tested.

Do not execute account-provisioning scripts against an existing directory without reviewing their behavior and testing them in an isolated environment. Reconstructed scripts have not necessarily been independently tested.

## Planned Additions

- Departmental security group assignment
- Active Directory user and group auditing
- NTFS permission verification
- SMB share security auditing
- Domain controller and DNS health verification
