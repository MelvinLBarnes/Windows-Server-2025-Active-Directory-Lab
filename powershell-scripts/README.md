# Active Directory PowerShell Automation

This directory contains PowerShell scripts used or reconstructed from the Windows Server 2025 Active Directory Home Lab.

## Available Scripts

| Script | Purpose |
|---|---|
| [01-Create-AD-Bulk-Users.ps1](01-Create-AD-Bulk-Users.ps1) | Reconstructed and sanitized Active Directory user provisioning script targeting 50 accounts per department across IT, HR, Finance, and Sales. |

## Lab Environment

- **Domain:** `adlab.test`
- **Domain Controller:** DC01 — Windows Server 2025
- **Departmental OUs:** IT, HR, Finance, Sales
- **Total provisioned accounts:** 200

## Security and Usage Notes

Scripts are provided for educational demonstration and technical documentation. Credentials have been removed or replaced with secure input methods.

Do not execute account-provisioning scripts against an existing directory without reviewing their behavior and testing them in an isolated environment. Reconstructed scripts have not necessarily been independently tested.

## Planned Additions

- Departmental security group assignment
- Active Directory user and group auditing
- NTFS permission verification
- SMB share security auditing
- Domain controller and DNS health verification
