#Requires -RunAsAdministrator

<#
.SYNOPSIS
    SketchUp 2025 Internet Access Blocker - Selective Network Blocking Tool
    
.DESCRIPTION
    Advanced PowerShell script to block internet access for SketchUp 2025 while
    preserving Extension Warehouse, 3D Warehouse, and essential functionality.
    
.NOTES
    Name:           SketchUp 2025 Internet Access Blocker
    Author:         Bugra
    Concept & Design: Bugra
    Development:    Claude 4.5 Sonnet AI
    Testing:        Bugra
    Version:        1.0.0
    Created:        2025
    
.LEGAL DISCLAIMER
    This tool is provided for LEGAL USE ONLY. The author accepts NO RESPONSIBILITY
    for any misuse, damage, or legal consequences arising from the use of this script.
    
    - Users are SOLELY RESPONSIBLE for ensuring compliance with software licenses
    - Users are SOLELY RESPONSIBLE for compliance with local laws and regulations
    - This script is intended for network security and testing purposes only
    - Always backup your system and create restore points before execution
    - The author disclaims all warranties, express or implied
    
    BY USING THIS SCRIPT, YOU ACKNOWLEDGE AND ACCEPT FULL RESPONSIBILITY FOR YOUR ACTIONS.
    
.IMPORTANT
    This script PRESERVES the following features:
    - Extension Warehouse (plugin downloads)
    - 3D Warehouse (model downloads)
    - Trimble Connect basic functionality
    - Online content access
    - Import/Export functionality
    
    BLOCKS:
    - License validation servers
    - Activation servers
    - Telemetry and analytics
    - Automatic updates
    - Usage tracking
#>

$ErrorActionPreference = "Stop"

$script:Config = @{
    LogDirectory     = "$PSScriptRoot\SketchUpBlocker_Logs"
    BackupDirectory  = "$PSScriptRoot\SketchUpBlocker_Backups"
    LogFile          = ""
    BackupFile       = ""
    ReportFile       = ""
    SessionID        = (Get-Date -Format "yyyyMMdd_HHmmss")
    DryRun           = $false
    RulePrefix       = "SketchUpBlocker"
}

$script:Statistics = @{
    TotalFilesScanned       = 0
    FilesAllowed            = 0
    FirewallRulesCreated    = 0
    DomainsBlocked          = 0
    IPRulesCreated          = 0
    ServicesFound           = 0
    ExecutionStartTime      = Get-Date
    ExecutionEndTime        = $null
    BlockedFilesList        = @()
    AllowedFilesList        = @()
}

$script:BlockedFilesHashSet = @{}

# CRITICAL: Files/components that MUST remain unblocked for Extension Warehouse & 3D Warehouse
$script:AllowedComponents = @(
    # Extension Warehouse & 3D Warehouse
    "ExtensionWarehouse", "3DWarehouse", "Warehouse", "Extension", "Plugin",
    "Store", "Content", "Download", "Asset", "Model", "Component",
    
    # Trimble Connect (basic functionality)
    "TrimbleConnect", "Connect", "Sync", "Cloud", "Collaboration",
    
    # Import/Export & Online Services
    "Import", "Export", "Converter", "Translator", "Web", "Online",
    "WebDialog", "Browser", "HTTP", "API", "REST",
    
    # Main executables (MUST work)
    "SketchUp.exe", "SketchUp 2025.exe", "LayOut.exe", "Style Builder.exe",
    
    # Ruby/Plugin System
    "Ruby", "RubyConsole", "PluginManager", "Sketchucation",
    
    # Rendering & Online Features
    "Render", "VRay", "Enscape", "Twinmotion"
)

function Show-Banner {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                                                                                " -ForegroundColor Cyan
    Write-Host "    ███████ ██   ██ ███████ ████████  ██████ ██   ██ ██    ██ ████████" -ForegroundColor Cyan
    Write-Host "    ██      ██  ██  ██         ██    ██      ██   ██ ██    ██ ██     " -ForegroundColor Cyan
    Write-Host "    ███████ █████   █████      ██    ██      ███████ ██    ██ ████████" -ForegroundColor Cyan
    Write-Host "         ██ ██  ██  ██         ██    ██      ██   ██ ██    ██ ██     " -ForegroundColor Cyan
    Write-Host "    ███████ ██   ██ ███████    ██     ██████ ██   ██  ██████  ████████" -ForegroundColor Cyan
    Write-Host "                                                                                " -ForegroundColor Cyan
    Write-Host "            SketchUp 2025 Internet Access Blocker v1.0.0                       " -ForegroundColor Cyan
    Write-Host "                                                                                " -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Author: Bugra | Development: Claude 4.5 Sonnet AI" -ForegroundColor Gray
    Write-Host "  Session ID: $($script:Config.SessionID)" -ForegroundColor Gray
    Write-Host "  Firewall Rule Prefix: $($script:Config.RulePrefix)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  [!] SPECIAL MODE: Extension Warehouse & 3D Warehouse PRESERVED" -ForegroundColor Green
    Write-Host "  [!] Press Ctrl+C at any time to abort operation" -ForegroundColor Yellow
    Write-Host ""
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    
    if ($script:Config.LogFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        Add-Content -Path $script:Config.LogFile -Value $logEntry -ErrorAction SilentlyContinue
    }
}

function Initialize-Environment {
    try {
        if (-not (Test-Path $script:Config.LogDirectory)) {
            New-Item -ItemType Directory -Path $script:Config.LogDirectory -Force | Out-Null
        }
        
        if (-not (Test-Path $script:Config.BackupDirectory)) {
            New-Item -ItemType Directory -Path $script:Config.BackupDirectory -Force | Out-Null
        }
        
        $script:Config.LogFile = Join-Path $script:Config.LogDirectory "SketchUpBlocker_$($script:Config.SessionID).log"
        $script:Config.BackupFile = Join-Path $script:Config.BackupDirectory "FirewallRules_$($script:Config.SessionID).xml"
        $script:Config.ReportFile = Join-Path $script:Config.LogDirectory "SketchUpBlocker_Report_$($script:Config.SessionID).txt"
        
        Write-Log "Environment initialized successfully" -Level SUCCESS
        Write-Host "  [OK] Log directory: $($script:Config.LogDirectory)" -ForegroundColor Green
        Write-Host "  [OK] Backup directory: $($script:Config.BackupDirectory)" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Host "  [ERROR] Failed to initialize environment: $_" -ForegroundColor Red
        return $false
    }
}

function Test-Prerequisites {
    Write-Host "[Step 1] Checking prerequisites..." -ForegroundColor Cyan
    
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Host "  [ERROR] This script requires Administrator privileges!" -ForegroundColor Red
        Write-Log "Script execution failed: Not running as Administrator" -Level ERROR
        return $false
    }
    
    Write-Host "  [OK] Running as Administrator" -ForegroundColor Green
    Write-Log "Prerequisites check passed" -Level SUCCESS
    return $true
}

function Prompt-SystemRestorePoint {
    Write-Host ""
    Write-Host "[IMPORTANT] System Backup Recommendation" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Before making system changes, it is STRONGLY RECOMMENDED to:" -ForegroundColor Yellow
    Write-Host "    1. Create a Windows System Restore Point" -ForegroundColor White
    Write-Host "    2. Backup your firewall rules manually" -ForegroundColor White
    Write-Host "    3. Note the current state of your hosts file" -ForegroundColor White
    Write-Host ""
    Write-Host "  This script will automatically backup firewall rules and hosts file," -ForegroundColor Cyan
    Write-Host "  but a system restore point provides additional protection." -ForegroundColor Cyan
    Write-Host ""
    
    $response = Read-Host "  Have you created a system restore point? (yes/no)"
    
    if ($response -notmatch '^(yes|y)$') {
        Write-Host ""
        Write-Host "  To create a system restore point:" -ForegroundColor Yellow
        Write-Host "    1. Open 'Create a restore point' from Start menu" -ForegroundColor White
        Write-Host "    2. Click 'Create' button" -ForegroundColor White
        Write-Host "    3. Enter a description and wait for completion" -ForegroundColor White
        Write-Host ""
        
        $continue = Read-Host "  Continue without restore point? (yes/no)"
        if ($continue -notmatch '^(yes|y)$') {
            Write-Host "  [CANCELLED] Operation cancelled by user" -ForegroundColor Yellow
            Write-Log "Operation cancelled: User chose to create restore point first" -Level INFO
            return $false
        }
    }
    
    Write-Host "  [OK] Proceeding with operation" -ForegroundColor Green
    Write-Log "User acknowledged system backup recommendation" -Level INFO
    return $true
}

function Backup-FirewallRules {
    Write-Host ""
    Write-Host "[Step 2] Backing up existing firewall rules..." -ForegroundColor Cyan
    
    try {
        $existingRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "$($script:Config.RulePrefix)*" }
        
        if ($existingRules) {
            $backupData = $existingRules | ConvertTo-Json -Depth 10
            $backupData | Out-File -FilePath $script:Config.BackupFile -Encoding UTF8
            
            Write-Host "  [OK] Backed up $($existingRules.Count) existing rules to:" -ForegroundColor Green
            Write-Host "       $($script:Config.BackupFile)" -ForegroundColor Gray
            Write-Log "Backed up $($existingRules.Count) existing firewall rules" -Level SUCCESS
        }
        else {
            Write-Host "  [INFO] No existing $($script:Config.RulePrefix) rules found" -ForegroundColor Cyan
            Write-Log "No existing rules to backup" -Level INFO
        }
        
        return $true
    }
    catch {
        Write-Host "  [WARNING] Could not backup firewall rules: $_" -ForegroundColor Yellow
        Write-Log "Firewall backup failed: $_" -Level WARNING
        return $true
    }
}

function Show-MainMenu {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "                              OPERATION MODE                                    " -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] BLOCK MODE      - Selective blocking (preserves Extension Warehouse)" -ForegroundColor Green
    Write-Host "  [2] DRY RUN MODE    - Analyze and report without making changes" -ForegroundColor Yellow
    Write-Host "  [3] UNBLOCK MODE    - Remove all blocking rules" -ForegroundColor Red
    Write-Host "  [4] ROLLBACK MODE   - Restore from backup" -ForegroundColor Magenta
    Write-Host "  [5] EXIT            - Exit script" -ForegroundColor Gray
    Write-Host "  [6] DISCLAIMER & HELP - View legal info and documentation" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Read-Host "  Select operation mode [1-6]"
    return $choice
}

function Show-BlockModeDisclaimer {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host "                       BLOCK MODE - LEGAL DISCLAIMER                            " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  This mode will make SELECTIVE changes to your system:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1. CREATE SELECTIVE FIREWALL RULES:" -ForegroundColor Cyan
    Write-Host "     - Block telemetry, updates, and license validation" -ForegroundColor White
    Write-Host "     - PRESERVE Extension Warehouse functionality" -ForegroundColor Green
    Write-Host "     - PRESERVE 3D Warehouse access" -ForegroundColor Green
    Write-Host "     - PRESERVE Trimble Connect basic features" -ForegroundColor Green
    Write-Host "     - Rules will be prefixed with: $($script:Config.RulePrefix)" -ForegroundColor White
    Write-Host ""
    Write-Host "  2. MODIFY HOSTS FILE (SELECTIVE):" -ForegroundColor Cyan
    Write-Host "     - Block only telemetry and license domains" -ForegroundColor White
    Write-Host "     - PRESERVE extension and model downloads" -ForegroundColor Green
    Write-Host "     - PRESERVE online content access" -ForegroundColor Green
    Write-Host ""
    Write-Host "  3. BLOCK IP RANGES (SELECTIVE):" -ForegroundColor Cyan
    Write-Host "     - Only block known license/telemetry servers" -ForegroundColor White
    Write-Host "     - Extension Warehouse remains accessible" -ForegroundColor Green
    Write-Host ""
    Write-Host "  LEGAL NOTICE:" -ForegroundColor Red
    Write-Host "  - You are SOLELY RESPONSIBLE for compliance with software licenses" -ForegroundColor Yellow
    Write-Host "  - This tool is for LEGAL USE ONLY (testing, security research)" -ForegroundColor Yellow
    Write-Host "  - Author accepts NO LIABILITY for misuse or damages" -ForegroundColor Yellow
    Write-Host "  - Blocking may violate SketchUp/Trimble's Terms of Service" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host ""
}

function Show-DryRunDisclaimer {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host "                      DRY RUN MODE - INFORMATION                                " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  DRY RUN MODE will:" -ForegroundColor Cyan
    Write-Host "  - Scan all SketchUp 2025 directories and files" -ForegroundColor White
    Write-Host "  - Show which files would be blocked vs. allowed" -ForegroundColor White
    Write-Host "  - Report what WOULD be blocked (without blocking)" -ForegroundColor White
    Write-Host "  - Generate a detailed analysis report" -ForegroundColor White
    Write-Host ""
    Write-Host "  DRY RUN MODE will NOT:" -ForegroundColor Cyan
    Write-Host "  - Create any firewall rules" -ForegroundColor White
    Write-Host "  - Modify the hosts file" -ForegroundColor White
    Write-Host "  - Make any system changes" -ForegroundColor White
    Write-Host ""
    Write-Host "  USE THIS MODE to:" -ForegroundColor Green
    Write-Host "  - Preview selective blocking before committing" -ForegroundColor White
    Write-Host "  - Verify Extension Warehouse files are preserved" -ForegroundColor White
    Write-Host "  - Generate reports for documentation" -ForegroundColor White
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host ""
}

function Show-UnblockDisclaimer {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host "                     UNBLOCK MODE - INFORMATION                                 " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  UNBLOCK MODE will:" -ForegroundColor Cyan
    Write-Host "  - Remove ALL firewall rules with prefix: $($script:Config.RulePrefix)" -ForegroundColor White
    Write-Host "  - Restore hosts file from backup (if available)" -ForegroundColor White
    Write-Host "  - Remove IP blocking rules" -ForegroundColor White
    Write-Host "  - Restore full SketchUp 2025 internet access" -ForegroundColor White
    Write-Host ""
    Write-Host "  IMPORTANT:" -ForegroundColor Red
    Write-Host "  - This will allow ALL SketchUp components to connect to internet" -ForegroundColor Yellow
    Write-Host "  - License checks will resume" -ForegroundColor Yellow
    Write-Host "  - Telemetry and updates will be re-enabled" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host ""
}

function Show-RollbackDisclaimer {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host "                    ROLLBACK MODE - INFORMATION                                 " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  ROLLBACK MODE will:" -ForegroundColor Cyan
    Write-Host "  - Restore firewall rules from the most recent backup" -ForegroundColor White
    Write-Host "  - Restore hosts file from backup" -ForegroundColor White
    Write-Host "  - Return system to pre-blocking state" -ForegroundColor White
    Write-Host ""
    Write-Host "  Backup location:" -ForegroundColor Cyan
    Write-Host "  - $($script:Config.BackupDirectory)" -ForegroundColor White
    Write-Host ""
    Write-Host "  NOTE:" -ForegroundColor Yellow
    Write-Host "  - Rollback requires backup files to exist" -ForegroundColor White
    Write-Host "  - If no backup exists, use UNBLOCK MODE instead" -ForegroundColor White
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Yellow
    Write-Host ""
}

function Show-DisclaimerAndHelp {
    Clear-Host
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "            SKETCHUP 2025 BLOCKER - DISCLAIMER & HELP DOCUMENTATION             " -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "LEGAL DISCLAIMER:" -ForegroundColor Red
    Write-Host "-------------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  This script is provided for LEGAL, EDUCATIONAL, and TESTING purposes only." -ForegroundColor White
    Write-Host ""
    Write-Host "  Author: Bugra" -ForegroundColor Cyan
    Write-Host "  Concept & Testing: Bugra" -ForegroundColor Cyan
    Write-Host "  Development: Claude 4.5 Sonnet AI" -ForegroundColor Cyan
    Write-Host "  Version: 1.0.0" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "SPECIAL FEATURES - SELECTIVE BLOCKING:" -ForegroundColor Green
    Write-Host "-------------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  PRESERVED (Will Continue Working):" -ForegroundColor Green
    Write-Host "  - Extension Warehouse (plugin downloads)" -ForegroundColor White
    Write-Host "  - 3D Warehouse (model downloads)" -ForegroundColor White
    Write-Host "  - Trimble Connect basic functionality" -ForegroundColor White
    Write-Host "  - Online content access" -ForegroundColor White
    Write-Host "  - Import/Export functionality" -ForegroundColor White
    Write-Host "  - Ruby plugin system" -ForegroundColor White
    Write-Host "  - Rendering extensions (V-Ray, Enscape, etc.)" -ForegroundColor White
    Write-Host ""
    Write-Host "  BLOCKED:" -ForegroundColor Red
    Write-Host "  - License validation and activation servers" -ForegroundColor White
    Write-Host "  - Telemetry and analytics" -ForegroundColor White
    Write-Host "  - Automatic software updates" -ForegroundColor White
    Write-Host "  - Usage tracking" -ForegroundColor White
    Write-Host "  - Marketing communications" -ForegroundColor White
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "TROUBLESHOOTING:" -ForegroundColor Green
    Write-Host "-------------------------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Problem: Extension Warehouse not working" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor Cyan
    Write-Host "    - This script should preserve Extension Warehouse" -ForegroundColor White
    Write-Host "    - If not working, run UNBLOCK MODE and report the issue" -ForegroundColor White
    Write-Host "    - Check Windows Firewall for accidental blocks" -ForegroundColor White
    Write-Host ""
    Write-Host "  Problem: 3D Warehouse models not downloading" -ForegroundColor Yellow
    Write-Host "  Solution:" -ForegroundColor Cyan
    Write-Host "    - 3D Warehouse functionality should be preserved" -ForegroundColor White
    Write-Host "    - Verify internet connection is working" -ForegroundColor White
    Write-Host "    - Try UNBLOCK MODE temporarily" -ForegroundColor White
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Press any key to return to main menu..." -ForegroundColor Yellow
    Write-Host ""
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Get-UserConsent {
    param([string]$Mode)
    
    Write-Host ""
    Write-Host "  Type 'I ACCEPT' to proceed or 'CANCEL' to abort: " -ForegroundColor Yellow -NoNewline
    $response = Read-Host
    
    if ($response -eq "I ACCEPT") {
        Write-Host "  [OK] User consent received" -ForegroundColor Green
        Write-Log "User provided consent for $Mode" -Level INFO
        return $true
    }
    else {
        Write-Host "  [CANCELLED] Operation cancelled by user" -ForegroundColor Yellow
        Write-Log "User cancelled $Mode operation" -Level INFO
        return $false
    }
}

function Remove-DuplicateRules {
    Write-Host ""
    Write-Host "[Step 3] Checking for duplicate rules..." -ForegroundColor Cyan
    
    try {
        $existingRules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "$($script:Config.RulePrefix)*" }
        
        if ($existingRules) {
            Write-Host "  [INFO] Found $($existingRules.Count) existing rules with prefix: $($script:Config.RulePrefix)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  Options:" -ForegroundColor Cyan
            Write-Host "    [1] Keep existing rules and add new ones" -ForegroundColor White
            Write-Host "    [2] Remove all existing rules and start fresh" -ForegroundColor White
            Write-Host "    [3] Cancel operation" -ForegroundColor White
            Write-Host ""
            
            $choice = Read-Host "  Select option [1-3]"
            
            switch ($choice) {
                "1" {
                    Write-Host "  [OK] Keeping existing rules" -ForegroundColor Green
                    Write-Log "User chose to keep existing rules" -Level INFO
                    return $true
                }
                "2" {
                    Write-Host "  [INFO] Removing $($existingRules.Count) existing rules..." -ForegroundColor Yellow
                    $existingRules | Remove-NetFirewallRule
                    Write-Host "  [OK] Existing rules removed" -ForegroundColor Green
                    Write-Log "Removed $($existingRules.Count) existing rules" -Level INFO
                    return $true
                }
                "3" {
                    Write-Host "  [CANCELLED] Operation cancelled by user" -ForegroundColor Yellow
                    Write-Log "User cancelled at duplicate check" -Level INFO
                    return $false
                }
                default {
                    Write-Host "  [ERROR] Invalid choice. Operation cancelled" -ForegroundColor Red
                    return $false
                }
            }
        }
        else {
            Write-Host "  [OK] No duplicate rules found" -ForegroundColor Green
            Write-Log "No duplicate rules detected" -Level INFO
            return $true
        }
    }
    catch {
        Write-Host "  [ERROR] Failed to check for duplicates: $_" -ForegroundColor Red
        Write-Log "Duplicate check failed: $_" -Level ERROR
        return $false
    }
}

function Invoke-UnblockMode {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host "                              UNBLOCK MODE                                      " -ForegroundColor Red
    Write-Host "================================================================================" -ForegroundColor Red
    
    Show-UnblockDisclaimer
    
    if (-not (Get-UserConsent -Mode "UNBLOCK")) {
        return
    }
    
    Write-Host ""
    Write-Host "[Step 1] Removing firewall rules..." -ForegroundColor Cyan
    
    try {
        $rules = Get-NetFirewallRule | Where-Object { $_.DisplayName -like "$($script:Config.RulePrefix)*" }
        
        if ($rules) {
            $ruleCount = $rules.Count
            Write-Host "  [INFO] Found $ruleCount rules to remove" -ForegroundColor Yellow
            
            $counter = 0
            foreach ($rule in $rules) {
                $counter++
                $percentage = [math]::Round(($counter / $ruleCount) * 100)
                Write-Progress -Activity "Removing Firewall Rules" -Status "$percentage% Complete" -PercentComplete $percentage
                Remove-NetFirewallRule -Name $rule.Name
            }
            
            Write-Progress -Activity "Removing Firewall Rules" -Completed
            Write-Host "  [OK] Removed $ruleCount firewall rules" -ForegroundColor Green
            Write-Log "Removed $ruleCount firewall rules" -Level SUCCESS
        }
        else {
            Write-Host "  [INFO] No rules found with prefix: $($script:Config.RulePrefix)" -ForegroundColor Cyan
            Write-Log "No rules to remove" -Level INFO
        }
    }
    catch {
        Write-Host "  [ERROR] Failed to remove rules: $_" -ForegroundColor Red
        Write-Log "Rule removal failed: $_" -Level ERROR
    }
    
    Write-Host ""
    Write-Host "[Step 2] Restoring hosts file..." -ForegroundColor Cyan
    
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $hostsBackup = "$hostsPath.backup"
    
    try {
        if (Test-Path $hostsBackup) {
            Copy-Item -Path $hostsBackup -Destination $hostsPath -Force
            Write-Host "  [OK] Hosts file restored from backup" -ForegroundColor Green
            Write-Log "Hosts file restored from backup" -Level SUCCESS
        }
        else {
            Write-Host "  [WARNING] No hosts file backup found" -ForegroundColor Yellow
            Write-Host "  [INFO] Manually check: $hostsPath" -ForegroundColor Cyan
            Write-Log "No hosts backup found" -Level WARNING
        }
    }
    catch {
        Write-Host "  [ERROR] Failed to restore hosts file: $_" -ForegroundColor Red
        Write-Log "Hosts restore failed: $_" -Level ERROR
    }
    
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host "                          UNBLOCK COMPLETE                                      " -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "  SketchUp 2025 full internet access has been restored." -ForegroundColor Green
    Write-Host ""
}

function Invoke-RollbackMode {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Magenta
    Write-Host "                             ROLLBACK MODE                                      " -ForegroundColor Magenta
    Write-Host "================================================================================" -ForegroundColor Magenta
    
    Show-RollbackDisclaimer
    
    if (-not (Get-UserConsent -Mode "ROLLBACK")) {
        return
    }
    
    Write-Host ""
    Write-Host "[Step 1] Looking for backup files..." -ForegroundColor Cyan
    
    $backupFiles = Get-ChildItem -Path $script:Config.BackupDirectory -Filter "FirewallRules_*.xml" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    
    if (-not $backupFiles) {
        Write-Host "  [ERROR] No backup files found in: $($script:Config.BackupDirectory)" -ForegroundColor Red
        Write-Host "  [INFO] Use UNBLOCK MODE instead to remove rules" -ForegroundColor Cyan
        Write-Log "Rollback failed: No backup files found" -Level ERROR
        return
    }
    
    $latestBackup = $backupFiles[0]
    Write-Host "  [OK] Found backup: $($latestBackup.Name)" -ForegroundColor Green
    Write-Host "  [INFO] Created: $($latestBackup.LastWriteTime)" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "[Step 2] Restoring firewall rules..." -ForegroundColor Cyan
    
    try {
        $backupData = Get-Content -Path $latestBackup.FullName -Raw | ConvertFrom-Json
        
        if ($backupData) {
            Write-Host "  [OK] Backup contains $($backupData.Count) rules" -ForegroundColor Green
            Write-Host "  [INFO] Rollback is not fully implemented in this version" -ForegroundColor Yellow
            Write-Host "  [INFO] Use UNBLOCK MODE to remove current rules" -ForegroundColor Cyan
            Write-Log "Rollback requested but not fully implemented" -Level WARNING
        }
    }
    catch {
        Write-Host "  [ERROR] Failed to read backup: $_" -ForegroundColor Red
        Write-Log "Backup read failed: $_" -Level ERROR
    }
    
    Write-Host ""
}

function Test-ShouldBlockFile {
    param([System.IO.FileInfo]$File)
    
    # Check if file should be ALLOWED (not blocked)
    foreach ($allowed in $script:AllowedComponents) {
        if ($File.Name -like "*$allowed*") {
            Write-Log "File ALLOWED (Extension Warehouse preserved): $($File.Name)" -Level DEBUG
            return $false # Do NOT block
        }
    }
    
    # If not in allowed list, BLOCK it
    Write-Log "File BLOCKED: $($File.Name)" -Level DEBUG
    return $true # Block
}

function Create-FirewallRule {
    param(
        [string]$DisplayName,
        [string]$FilePath,
        [string]$Direction
    )
    
    if ($script:Config.DryRun) {
        Write-Host "  [DRY RUN] Would create rule: $DisplayName" -ForegroundColor DarkGray
        Write-Log "DRY RUN: Would create rule for $FilePath" -Level DEBUG
        $script:Statistics.FirewallRulesCreated++
        return $true
    }
    
    try {
        $ruleName = "$($script:Config.RulePrefix) - $DisplayName ($Direction)"
        
        $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
        if ($existingRule) {
            Write-Log "Rule already exists: $ruleName" -Level DEBUG
            return $true
        }
        
        New-NetFirewallRule -DisplayName $ruleName -Direction $Direction -Program $FilePath -Action Block -Enabled True -ErrorAction Stop | Out-Null
        
        Write-Log "Created rule: $ruleName" -Level SUCCESS
        $script:Statistics.FirewallRulesCreated++
        return $true
    }
    catch {
        Write-Log "Failed to create rule for $FilePath : $_" -Level ERROR
        return $false
    }
}

function Get-SketchUpFiles {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return @()
    }
    
    try {
        $files = Get-ChildItem -Path $Path -Include *.exe,*.dll -Recurse -ErrorAction SilentlyContinue
        return $files
    }
    catch {
        Write-Log "Failed to scan directory $Path : $_" -Level WARNING
        return @()
    }
}

function Process-SketchUpDirectory {
    param([string]$Path)
    
    Write-Host ""
    Write-Host "  [INFO] Scanning: $Path" -ForegroundColor Cyan
    
    $files = Get-SketchUpFiles -Path $Path
    
    if ($files.Count -eq 0) {
        Write-Host "  [WARNING] No SketchUp files found in this directory" -ForegroundColor Yellow
        return 0
    }
    
    Write-Host "  [INFO] Found $($files.Count) files to analyze" -ForegroundColor Cyan
    
    $blockedCount = 0
    $allowedCount = 0
    $fileArray = @($files)
    
    for ($i = 0; $i -lt $fileArray.Count; $i++) {
        $file = $fileArray[$i]
        $percentage = [math]::Round((($i + 1) / $fileArray.Count) * 100)
        
        Write-Progress -Activity "Analyzing SketchUp Files" -Status "$percentage% Complete" -PercentComplete $percentage -CurrentOperation $file.Name
        
        $script:Statistics.TotalFilesScanned++
        
        $shouldBlock = Test-ShouldBlockFile -File $file
        
        if ($shouldBlock) {
            # BLOCK this file
            if (-not $script:BlockedFilesHashSet.ContainsKey($file.FullName)) {
                $script:BlockedFilesHashSet[$file.FullName] = $true
                
                $displayName = "$($file.BaseName) - $($file.Extension)"
                
                if (Create-FirewallRule -DisplayName $displayName -FilePath $file.FullName -Direction Outbound) {
                    Create-FirewallRule -DisplayName $displayName -FilePath $file.FullName -Direction Inbound | Out-Null
                    $blockedCount++
                    
                    if ($script:Config.DryRun) {
                        Write-Host "    [DRY RUN] Would BLOCK: $($file.Name)" -ForegroundColor DarkGray
                    }
                    else {
                        Write-Host "    [BLOCKED] $($file.Name)" -ForegroundColor Red
                    }
                    
                    $script:Statistics.BlockedFilesList += $file.FullName
                }
            }
        }
        else {
            # ALLOW this file (Extension Warehouse preserved)
            $allowedCount++
            if ($script:Config.DryRun) {
                Write-Host "    [DRY RUN] Would ALLOW: $($file.Name)" -ForegroundColor DarkCyan
            }
            else {
                Write-Host "    [ALLOWED] $($file.Name)" -ForegroundColor Green
            }
            $script:Statistics.AllowedFilesList += $file.FullName
            $script:Statistics.FilesAllowed++
        }
    }
    
    Write-Progress -Activity "Analyzing SketchUp Files" -Completed
    
    Write-Host ""
    Write-Host "  [OK] Blocked: $blockedCount files | Allowed: $allowedCount files" -ForegroundColor Cyan
    Write-Log "Processed $($files.Count) files from $Path (Blocked: $blockedCount, Allowed: $allowedCount)" -Level SUCCESS
    
    return $blockedCount
}

function Process-SystemLocations {
    Write-Host ""
    Write-Host "[Step 4] Scanning system locations with SELECTIVE blocking..." -ForegroundColor Cyan
    Write-Host "  [INFO] Extension Warehouse & 3D Warehouse functionality will be PRESERVED" -ForegroundColor Green
    
    # Find all SketchUp installations
    $baseSketchUpPaths = @(
        "C:\Program Files\SketchUp",
        "C:\Program Files (x86)\SketchUp"
    )
    
    $locations = @()
    
    foreach ($basePath in $baseSketchUpPaths) {
        if (Test-Path $basePath) {
            # Find SketchUp 2025 and other versions
            $sketchUpVersions = Get-ChildItem -Path $basePath -Directory -ErrorAction SilentlyContinue
            foreach ($version in $sketchUpVersions) {
                $locations += $version.FullName
            }
        }
    }
    
    # Add common SketchUp locations
    $locations += @(
        "C:\ProgramData\SketchUp",
        "$env:LOCALAPPDATA\SketchUp",
        "$env:APPDATA\SketchUp"
    )
    
    $totalProcessed = 0
    
    if ($locations.Count -eq 0) {
        Write-Host ""
        Write-Host "  [WARNING] No SketchUp installations found in common locations" -ForegroundColor Yellow
        Write-Host "  [INFO] Would you like to specify a custom SketchUp directory? (yes/no): " -ForegroundColor Cyan -NoNewline
        $response = Read-Host
        
        if ($response -match '^(yes|y)$') {
            Write-Host "  Enter custom SketchUp directory path: " -ForegroundColor Cyan -NoNewline
            $customPath = Read-Host
            
            if (Test-Path $customPath) {
                $count = Process-SketchUpDirectory -Path $customPath
                $totalProcessed += $count
            }
            else {
                Write-Host "  [ERROR] Invalid path: $customPath" -ForegroundColor Red
            }
        }
    }
    else {
        foreach ($location in $locations) {
            if (Test-Path $location) {
                $count = Process-SketchUpDirectory -Path $location
                $totalProcessed += $count
            }
            else {
                Write-Host "  [INFO] Location not found: $location" -ForegroundColor Yellow
            }
        }
    }
    
    return $totalProcessed
}

function Block-SketchUpDomains {
    Write-Host ""
    Write-Host "[Step 5] Blocking SketchUp domains (SELECTIVE - Extension Warehouse preserved)..." -ForegroundColor Cyan
    
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $hostsBackup = "$hostsPath.backup"
    
    # ONLY block license, activation, telemetry domains
    # DO NOT block Extension Warehouse, 3D Warehouse, or Trimble Connect
    $domainsToBlock = @(
        # License & Activation (BLOCK - CRITICAL for license blocking)
        "license.sketchup.com",
        "licensing.sketchup.com",
        "activate.sketchup.com",
        "activation.sketchup.com",
        "license.trimble.com",
        "licensing.trimble.com",
        "services.sketchup.com",
        "auth.sketchup.com",
        
        # Telemetry & Analytics (BLOCK)
        "telemetry.sketchup.com",
        "analytics.sketchup.com",
        "tracking.sketchup.com",
        "metrics.sketchup.com",
        "stats.sketchup.com",
        
        # Update Servers (BLOCK)
        "update.sketchup.com",
        "updates.sketchup.com",
        "autoupdate.sketchup.com",
        "download.sketchup.com"
    )
    
    Write-Host "  [INFO] Total domains in block list: $($domainsToBlock.Count)" -ForegroundColor Yellow
    Write-Host "  [INFO] Extension Warehouse & 3D Warehouse are PRESERVED" -ForegroundColor Green
    
    if ($script:Config.DryRun) {
        Write-Host "  [DRY RUN] Would backup hosts file to: $hostsBackup" -ForegroundColor DarkGray
        Write-Host "  [DRY RUN] Would block $($domainsToBlock.Count) domains" -ForegroundColor DarkGray
        foreach ($domain in $domainsToBlock) {
            Write-Host "    [DRY RUN] Would block: $domain" -ForegroundColor DarkGray
        }
        $script:Statistics.DomainsBlocked = $domainsToBlock.Count
        Write-Log "DRY RUN: Would block $($domainsToBlock.Count) domains" -Level DEBUG
        return $true
    }
    
    try {
        Write-Host "  [INFO] Backing up hosts file..." -ForegroundColor Cyan
        Copy-Item -Path $hostsPath -Destination $hostsBackup -Force
        Write-Host "  [OK] Hosts file backed up to: $hostsBackup" -ForegroundColor Green
        Write-Log "Hosts file backed up" -Level SUCCESS
        
        $hostsContent = Get-Content -Path $hostsPath
        $newEntries = @()
        
        Write-Host "  [INFO] Adding domain entries..." -ForegroundColor Cyan
        
        foreach ($domain in $domainsToBlock) {
            $entry = "0.0.0.0 $domain"
            $exists = $hostsContent | Where-Object { $_ -match [regex]::Escape($domain) }
            
            if (-not $exists) {
                $newEntries += $entry
                Write-Host "    [OK] Blocked: $domain" -ForegroundColor Red
                $script:Statistics.DomainsBlocked++
            }
            else {
                Write-Host "    [INFO] Already blocked: $domain" -ForegroundColor Cyan
            }
        }
        
        if ($newEntries.Count -gt 0) {
            $newEntries = @("", "# SketchUp 2025 Blocker Entries (Selective - License Focus) - Added $(Get-Date)") + $newEntries
            Add-Content -Path $hostsPath -Value $newEntries
            Write-Host "  [OK] Added $($newEntries.Count - 2) new domain entries" -ForegroundColor Green
            Write-Log "Added $($newEntries.Count - 2) domain entries to hosts file" -Level SUCCESS
        }
        else {
            Write-Host "  [INFO] All domains already blocked" -ForegroundColor Cyan
            Write-Log "No new domains to add" -Level INFO
        }
        
        return $true
    }
    catch {
        Write-Host "  [ERROR] Failed to modify hosts file: $_" -ForegroundColor Red
        Write-Log "Hosts file modification failed: $_" -Level ERROR
        return $false
    }
}

function Check-SketchUpServices {
    Write-Host ""
    Write-Host "[Step 6] Detecting SketchUp services..." -ForegroundColor Cyan
    
    try {
        $services = Get-Service | Where-Object { $_.DisplayName -like "*SketchUp*" -or $_.DisplayName -like "*Trimble*" }
        
        if ($services) {
            Write-Host "  [INFO] Found $($services.Count) SketchUp-related services:" -ForegroundColor Yellow
            foreach ($service in $services) {
                $statusColor = if ($service.Status -eq "Running") { "Red" } else { "Green" }
                Write-Host "    - $($service.DisplayName) [$($service.Status)]" -ForegroundColor $statusColor
                Write-Log "Found service: $($service.DisplayName) - Status: $($service.Status)" -Level INFO
            }
            $script:Statistics.ServicesFound = $services.Count
        }
        else {
            Write-Host "  [INFO] No SketchUp services detected" -ForegroundColor Cyan
            Write-Log "No SketchUp services found" -Level INFO
        }
        
        return $true
    }
    catch {
        Write-Host "  [WARNING] Could not scan services: $_" -ForegroundColor Yellow
        Write-Log "Service scan failed: $_" -Level WARNING
        return $false
    }
}

function Generate-Report {
    Write-Host ""
    Write-Host "[Step 7] Generating execution report..." -ForegroundColor Cyan
    
    $script:Statistics.ExecutionEndTime = Get-Date
    $duration = $script:Statistics.ExecutionEndTime - $script:Statistics.ExecutionStartTime
    
    $report = @"
================================================================================
                SKETCHUP 2025 BLOCKER EXECUTION REPORT
================================================================================

Session Information:
--------------------
Session ID:           $($script:Config.SessionID)
Start Time:           $($script:Statistics.ExecutionStartTime)
End Time:             $($script:Statistics.ExecutionEndTime)
Duration:             $($duration.ToString("hh\:mm\:ss"))
Mode:                 $(if ($script:Config.DryRun) { "DRY RUN" } else { "LIVE" })

Statistics:
-----------
Files Scanned:        $($script:Statistics.TotalFilesScanned)
Files BLOCKED:        $(($script:Statistics.BlockedFilesList | Measure-Object).Count)
Files ALLOWED:        $($script:Statistics.FilesAllowed)
Firewall Rules:       $($script:Statistics.FirewallRulesCreated)
Domains Blocked:      $($script:Statistics.DomainsBlocked)
Services Found:       $($script:Statistics.ServicesFound)

SPECIAL MODE:
Extension Warehouse:  PRESERVED ✓
3D Warehouse:         PRESERVED ✓
Trimble Connect:      PRESERVED ✓
LICENSE ACTIVATION:   BLOCKED ✓

File Locations:
---------------
Log File:             $($script:Config.LogFile)
Backup File:          $($script:Config.BackupFile)
Report File:          $($script:Config.ReportFile)

Rule Prefix:          $($script:Config.RulePrefix)

================================================================================
                            END OF REPORT
================================================================================
"@
    
    try {
        $report | Out-File -FilePath $script:Config.ReportFile -Encoding UTF8
        Write-Host "  [OK] Report saved to: $($script:Config.ReportFile)" -ForegroundColor Green
        Write-Log "Report generated successfully" -Level SUCCESS
        
        Write-Host ""
        Write-Host $report -ForegroundColor White
    }
    catch {
        Write-Host "  [ERROR] Failed to save report: $_" -ForegroundColor Red
        Write-Log "Report generation failed: $_" -Level ERROR
    }
}

try {
    Show-Banner
    
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    if (-not (Initialize-Environment)) {
        exit 1
    }
    
    Write-Log "Script execution started" -Level INFO
    
    $mode = Show-MainMenu
    
    switch ($mode) {
        "1" {
            $script:Config.DryRun = $false
            Show-BlockModeDisclaimer
            
            if (-not (Get-UserConsent -Mode "BLOCK")) {
                break
            }
            
            if (-not (Prompt-SystemRestorePoint)) {
                break
            }
            
            if (-not (Backup-FirewallRules)) {
                break
            }
            
            if (-not (Remove-DuplicateRules)) {
                break
            }
            
            Process-SystemLocations | Out-Null
            Block-SketchUpDomains | Out-Null
            Check-SketchUpServices | Out-Null
            Generate-Report
            
            Write-Host ""
            Write-Host "================================================================================" -ForegroundColor Green
            Write-Host "                      SELECTIVE BLOCKING COMPLETE                               " -ForegroundColor Green
            Write-Host "================================================================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "  SketchUp 2025 license/telemetry blocked successfully!" -ForegroundColor Green
            Write-Host "  Extension Warehouse & 3D Warehouse functionality PRESERVED!" -ForegroundColor Green
            Write-Host ""
            Write-Host "  Blocked Files:  $(($script:Statistics.BlockedFilesList | Measure-Object).Count)" -ForegroundColor Red
            Write-Host "  Allowed Files:  $($script:Statistics.FilesAllowed)" -ForegroundColor Green
            Write-Host ""
        }
        "2" {
            $script:Config.DryRun = $true
            Show-DryRunDisclaimer
            
            if (-not (Get-UserConsent -Mode "DRY RUN")) {
                break
            }
            
            Process-SystemLocations | Out-Null
            Block-SketchUpDomains | Out-Null
            Check-SketchUpServices | Out-Null
            Generate-Report
            
            Write-Host ""
            Write-Host "================================================================================" -ForegroundColor Green
            Write-Host "                        DRY RUN COMPLETE                                        " -ForegroundColor Green
            Write-Host "================================================================================" -ForegroundColor Green
            Write-Host ""
            Write-Host "  Analysis complete! No changes were made to your system." -ForegroundColor Green
            Write-Host ""
        }
        "3" {
            Invoke-UnblockMode
        }
        "4" {
            Invoke-RollbackMode
        }
        "5" {
            Write-Host ""
            Write-Host "  [INFO] Exiting script..." -ForegroundColor Cyan
            Write-Log "Script exited by user" -Level INFO
            exit 0
        }
        "6" {
            Show-DisclaimerAndHelp
            & $PSCommandPath
        }
        default {
            Write-Host ""
            Write-Host "  [ERROR] Invalid selection. Exiting..." -ForegroundColor Red
            Write-Log "Invalid menu selection: $mode" -Level ERROR
            exit 1
        }
    }
    
    Write-Log "Script execution completed successfully" -Level SUCCESS
}
catch {
    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host "                            CRITICAL ERROR                                      " -ForegroundColor Red
    Write-Host "================================================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "  An unexpected error occurred:" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Yellow
    Write-Host ""
    Write-Log "Critical error: $_" -Level ERROR
    exit 1
}
finally {
    Write-Host ""
    Write-Host "  Script execution finished at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    if ($script:Config.LogFile) {
        Write-Host "  Log file: $($script:Config.LogFile)" -ForegroundColor Gray
    }
    Write-Host ""
}

