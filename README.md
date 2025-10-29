# SketchUp 2025 Blocker

PowerShell script for selective network blocking of SketchUp 2025 applications and services while preserving Extension Warehouse, 3D Warehouse, and Trimble Connect functionality.

## Overview

Advanced network blocking tool that selectively restricts SketchUp 2025's internet connectivity. Unlike traditional blockers, this script preserves Extension Warehouse, 3D Warehouse, Trimble Connect, and online content access capabilities while blocking telemetry and license validation.

## Features

- Selective blocking: Extension Warehouse & 3D Warehouse preserved
- Windows Firewall rule creation (inbound/outbound)
- Hosts file modification with selective domain blocking
- Service detection and reporting
- Automated backup and rollback capability
- Multiple operation modes (Block, Unblock, Dry Run, Rollback)
- Comprehensive logging and execution reports
- Ruby plugin system support

## Special Capabilities

### Preserved Functions
- Extension Warehouse (plugin downloads)
- 3D Warehouse (model downloads)
- Trimble Connect basic functionality
- Online content access
- Import/Export functionality
- Ruby plugin system
- Rendering extensions (V-Ray, Enscape, Twinmotion, etc.)
- Browser and WebDialog functionality
- API and REST services

### Blocked Functions
- License validation servers
- Activation servers
- Telemetry and analytics
- Automatic software updates
- Usage tracking
- Marketing communications

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
1. Block Mode - Apply selective blocking rules
2. Dry Run Mode - Preview changes without applying
3. Unblock Mode - Remove all blocking rules
4. Rollback Mode - Restore from backup
5. Exit
6. Disclaimer & Help

## Technical Details

### Blocking Methodology

1. **Selective Firewall Rules**: Blocks only non-essential components
2. **Selective DNS Blocking**: Only telemetry and license domains blocked
3. **Service Detection**: Identifies and reports SketchUp-related Windows services
4. **Smart Filtering**: Preserves Extension Warehouse and 3D Warehouse modules

### File Locations Scanned

- `C:\Program Files\SketchUp\SketchUp 2025\`
- `C:\Program Files (x86)\SketchUp\`
- `C:\ProgramData\SketchUp\`
- `%LOCALAPPDATA%\SketchUp\`
- `%APPDATA%\SketchUp\`
- Custom installation directories (user-specified)

### Allowed Components (Not Blocked)

Components containing these keywords remain unblocked:
- ExtensionWarehouse, 3DWarehouse, Warehouse, Extension, Plugin
- Store, Content, Download, Asset, Model, Component
- TrimbleConnect, Connect, Sync, Cloud, Collaboration
- Import, Export, Converter, Translator, Web, Online
- WebDialog, Browser, HTTP, API, REST
- SketchUp.exe, LayOut.exe, Style Builder.exe
- Ruby, RubyConsole, PluginManager
- Render, VRay, Enscape, Twinmotion

### Blocked Domains (Selective List)

- license.sketchup.com
- licensing.sketchup.com
- activate.sketchup.com
- activation.sketchup.com
- license.trimble.com
- licensing.trimble.com
- services.sketchup.com
- auth.sketchup.com
- telemetry.sketchup.com
- analytics.sketchup.com
- update.sketchup.com

Note: Extension Warehouse, 3D Warehouse, and online content domains are NOT blocked.

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

**IMPORTANT**: Blocking license validation servers may violate SketchUp/Trimble's Terms of Service. This tool is intended for testing, security research, and legal use cases only.

## Troubleshooting

### Extension Warehouse Not Working
- This script should preserve Extension Warehouse functionality
- If not working, run UNBLOCK MODE and report the issue
- Check Windows Firewall for accidental blocks

### 3D Warehouse Models Not Downloading
- 3D Warehouse functionality should be preserved
- Verify internet connection is working
- Try UNBLOCK MODE temporarily if issues persist

### Plugins Not Installing
- Ruby plugin system should remain functional
- Ensure Extension Warehouse is accessible
- Check firewall rules didn't accidentally block plugin system

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
- Special Mode: Selective Blocking with Extension Warehouse & 3D Warehouse Preservation

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

