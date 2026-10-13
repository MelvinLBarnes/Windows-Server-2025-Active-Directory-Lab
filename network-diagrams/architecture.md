
# Active Directory Lab Network Architecture

```mermaid
flowchart TB
    Internet["External Network / Internet"]
    NAT["VirtualBox NAT Networking"]
    Lab["AD-LAB Host-Only Network<br/>192.168.56.0/24"]

    DC["DC01<br/>Windows Server 2025<br/>AD DS + DNS<br/>192.168.56.10"]
    Client["WIN11-CLIENT01<br/>Windows 11 Pro<br/>192.168.56.20"]

    Internet --- NAT
    NAT --- DC
    NAT --- Client
    DC --- Lab
    Client --- Lab
```

## Network Details

- **Domain:** adlab.test
- **Domain Controller:** DC01
- **DNS Server:** 192.168.56.10
- **Windows 11 Client:** 192.168.56.20
- **Internal Network:** AD-LAB (Host-Only)
- **Outbound Connectivity:** VirtualBox NAT
