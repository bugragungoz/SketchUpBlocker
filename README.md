# SketchUp 2025 Blocker

PowerShell script for complete network blocking of SketchUp 2025 applications and services. Full internet isolation with no exceptions.

## Overview

Advanced network blocking tool that completely blocks ALL internet access for SketchUp 2025. This script implements multi-layer blocking through Windows Firewall rules, DNS resolution manipulation, and comprehensive domain blocking to ensure complete network isolation.

## Features

- FULL BLOCK MODE: Complete network isolation
- Windows Firewall rule creation for ALL executables and DLLs (inbound/outbound)
- Comprehensive hosts file modification (60+ domains blocked)
- Service detection and reporting
- Automated backup and rollback capability
- Multiple operation modes (Block, Unblock, Dry Run, Rollback)
- Comprehensive logging and execution reports
- SketchUp 2025 optimized file scanning

## Blocking Capabilities

### Everything Blocked (No Exceptions)
- ALL SketchUp executables and DLLs blocked from internet
- License validation and activation servers
- Telemetry and analytics
- Automatic software updates
- Extension Warehouse and plugin downloads
- 3D Warehouse and model downloads
- Trimble Connect and cloud features
- ALL online content and services
- ALL SketchUp and Trimble domains

### Result
- SketchUp will have ZERO internet connectivity
- Completely offline operation only
- No network access whatsoever

## Usage

1. Open PowerShell as Administrator

2. Navigate to script directory
   ```powershell
   cd C:\path\to\script\directory
   ```

3. Set execution policy for current session
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
   ```

4. Run the script
   ```powershell
   .\SketchUpBlocker.ps1
   ```

Select operation mode from interactive menu:
1. Block Mode - Apply FULL blocking rules
2. Dry Run Mode - Preview changes without applying
3. Unblock Mode - Remove all blocking rules
4. Rollback Mode - Restore from backup
5. Exit
6. Disclaimer & Help

## Technical Details

### Blocking Methodology

1. **Complete Firewall Rules**: Blocks ALL SketchUp files from network access
2. **Comprehensive DNS Blocking**: All SketchUp and Trimble domains redirected
3. **Service Detection**: Identifies and reports SketchUp-related Windows services
4. **Multi-Layer Protection**: Firewall + Hosts file + Domain blocking

### File Locations Scanned

- `C:\Program Files\SketchUp\SketchUp 2025\`
- `C:\Program Files\SketchUp\` (all versions)
- `C:\Program Files (x86)\SketchUp\`
- `C:\ProgramData\SketchUp\`
- `%LOCALAPPDATA%\SketchUp\`
- `%APPDATA%\SketchUp\`
- Custom installation directories (user-specified)

### Blocked Domains (60+ Domains)

#### Main SketchUp Domains
- sketchup.com
- www.sketchup.com
- app.sketchup.com
- my.sketchup.com

#### License & Activation
- license.sketchup.com
- licensing.sketchup.com
- activate.sketchup.com
- activation.sketchup.com
- auth.sketchup.com
- identity.sketchup.com
- services.sketchup.com

#### Extension Warehouse & 3D Warehouse
- extensions.sketchup.com
- extensionwarehouse.sketchup.com
- 3dwarehouse.sketchup.com
- warehouse.sketchup.com

#### Telemetry & Analytics
- telemetry.sketchup.com
- analytics.sketchup.com
- tracking.sketchup.com
- metrics.sketchup.com
- stats.sketchup.com
- crashreport.sketchup.com
- feedback.sketchup.com

#### Update Servers
- update.sketchup.com
- updates.sketchup.com
- autoupdate.sketchup.com
- download.sketchup.com
- downloads.sketchup.com

#### API & Services
- api.sketchup.com
- connect-api.sketchup.com
- assets.sketchup.com
- content.sketchup.com

#### Trimble Domains
- trimble.com
- www.trimble.com
- license.trimble.com
- licensing.trimble.com
- identity.trimble.com
- id.trimble.com
- connect.trimble.com
- cloud.trimble.com
- api.trimble.com
- telemetry.trimble.com
- analytics.trimble.com

#### Trimble Connect
- trimbleconnect.com
- app.connect.trimble.com
- sync.trimbleconnect.com

#### CDN & Assets
- cdn.sketchup.com
- static.sketchup.com
- assets-prod.sketchup.com

#### Legacy & Alternative Domains
- su-cdn.azureedge.net
- sketchup.azureedge.net
- sketchuphelp.com
- help.sketchup.com
- forums.sketchup.com
- community.sketchup.com

And more...

### Log Files

All operations generate logs in `SketchUpBlocker_Logs/` directory:
- Execution logs: `SketchUpBlocker_YYYYMMDD_HHMMSS.log`
- Backup files: `SketchUpBlocker_Backups/FirewallRules_*.xml`
- Reports: `SketchUpBlocker_Report_*.txt`

## Legal Disclaimer

This tool is provided for legal use only. Users are solely responsible for:
- Compliance with software licenses
- Compliance with local laws and regulations
- Any consequences arising from use of this script

The author accepts no responsibility for misuse, damage, or legal consequences.

**IMPORTANT**: Blocking SketchUp's internet access may violate SketchUp/Trimble's Terms of Service. This tool is intended for testing, security research, network isolation, and legal use cases only.

## Troubleshooting

### Need to Temporarily Enable Internet
- Run script and select UNBLOCK MODE (option 3)
- This removes all firewall rules and restores hosts file
- Re-run BLOCK MODE when finished

### SketchUp Still Connecting to Internet
- Verify Windows Firewall service is running
- Check hosts file was modified correctly
- Run BLOCK MODE again (option 1)

### Need to Restore Previous State
- Run script and select ROLLBACK MODE (option 4)
- Or use UNBLOCK MODE to completely remove all blocks

## Uninstallation

Remove all blocking rules:

```powershell
.\SketchUpBlocker.ps1
# Select option 3: UNBLOCK MODE
```

## Technical Specifications

- Script Version: 1.0.0
- Rule Prefix: SketchUpBlocker
- Session ID Format: YYYYMMDD_HHMMSS
- Backup Format: XML
- Supported Version: SketchUp 2025 (compatible with other versions)
- Block Mode: FULL BLOCK - Complete Network Isolation
- Domains Blocked: 60+ domains
- Files Blocked: ALL .exe and .dll files in SketchUp directories

## System Requirements

- Windows 10/11
- PowerShell 5.1 or higher
- Administrator privileges
- SketchUp 2025 (or other versions)

## Author

Bugra

## Development

Claude 4.5 Sonnet AI

## License

See LICENSE file for details.
