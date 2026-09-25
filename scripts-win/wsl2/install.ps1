#!/usr/bin/env pwsh
# File: install.ps1
#
# Usage:
#   install.ps1 [-Help]
#
# Purpose:
#   Enables the WSL2 Windows features via DISM for Intune deployment.
#
# Author: Ops Team
# Created: February 2026
#
# Intune runs this as SYSTEM. Exit 3010 = soft reboot required.
# Do not use em dashes or non-ASCII characters (Windows PowerShell 5.1 compatibility).

[CmdletBinding()]
param(
    [switch]$Help
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

#------------------------------------------------------------------------------
# SCRIPT METADATA
#------------------------------------------------------------------------------

$SCRIPT_ID          = "wsl2-install"
$SCRIPT_NAME        = "WSL2 Feature Installer"
$SCRIPT_VER         = "0.3.0"
$SCRIPT_DESCRIPTION = "Enables WSL2 Windows features via DISM for Intune deployment."
$SCRIPT_CATEGORY    = "DEPLOY"

#------------------------------------------------------------------------------
# CONFIGURATION
#------------------------------------------------------------------------------

$WSL_FEATURE        = "Microsoft-Windows-Subsystem-Linux"
$VM_FEATURE         = "VirtualMachinePlatform"
$MIN_BUILD          = 22000   # Windows 11 (Rancher Desktop 1.24 requires it)

#------------------------------------------------------------------------------
# LOGGING
#------------------------------------------------------------------------------

function log_time    { Get-Date -Format 'HH:mm:ss' }
function log_info    { param([string]$msg) Write-Host "[$( log_time )] INFO  $msg" }
function log_success { param([string]$msg) Write-Host "[$( log_time )] OK    $msg" }
function log_error   { param([string]$msg) Write-Host "[$( log_time )] ERROR $msg" }
function log_warning { param([string]$msg) Write-Host "[$( log_time )] WARN  $msg" }
function log_start   { log_info "Starting: $SCRIPT_NAME Ver: $SCRIPT_VER" }

#------------------------------------------------------------------------------
# HELP
#------------------------------------------------------------------------------

function Show-Help {
    Write-Host "$SCRIPT_NAME (v$SCRIPT_VER)"
    Write-Host "$SCRIPT_DESCRIPTION"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  $SCRIPT_ID [-Help]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Help     Show this help message"
    Write-Host ""
    Write-Host "Exit codes:"
    Write-Host "  0         Features already enabled (no action needed)"
    Write-Host "  3010      Features enabled, reboot required"
    Write-Host "  1         Error"
    Write-Host ""
    Write-Host "Metadata:"
    Write-Host "  ID:       $SCRIPT_ID"
    Write-Host "  Category: $SCRIPT_CATEGORY"
}

if ($Help) {
    Show-Help
    exit 0
}

#------------------------------------------------------------------------------
# HELPER FUNCTIONS
#------------------------------------------------------------------------------

function Get-HostArchitecture {
    # Win32_Processor reports the real CPU, even when an x64 PowerShell runs
    # under emulation on an ARM64 PC (where PROCESSOR_ARCHITECTURE says AMD64).
    # Architecture codes: 9 = x64, 12 = ARM64, 0 = x86, 5 = ARM
    try {
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1
        switch ([int]$cpu.Architecture) {
            9       { return "x64" }
            12      { return "ARM64" }
            0       { return "x86" }
            5       { return "ARM" }
            default { return "unknown($($cpu.Architecture))" }
        }
    }
    catch {
        $arch = $env:PROCESSOR_ARCHITEW6432
        if (-not $arch) { $arch = $env:PROCESSOR_ARCHITECTURE }
        if ($arch -eq "AMD64") { return "x64" }
        return $arch
    }
}

function Test-HostPlatform {
    # Returns $true when the PC is Windows 11 (build >= $MinBuild) on x64.
    # Parameters let the tests pass fake values.
    param(
        [int]$Build = [System.Environment]::OSVersion.Version.Build,
        [string]$Architecture = (Get-HostArchitecture),
        [int]$MinBuild = $MIN_BUILD,
        [string]$BuildCode = "ERR002",
        [string]$ArchCode = "ERR008"
    )
    $ok = $true
    if ($Build -lt $MinBuild) {
        log_error "${BuildCode}: This PC runs Windows build $Build. Windows 11 is required."
        log_error "${BuildCode}: Rancher Desktop 1.24 does not support Windows 10 (minimum build: $MinBuild)"
        $ok = $false
    }
    else {
        log_success "Windows build $Build meets minimum ($MinBuild, Windows 11)"
    }
    if ($Architecture -ne "x64") {
        log_error "${ArchCode}: This PC has an $Architecture processor. Only x64 PCs are supported."
        log_error "${ArchCode}: The Rancher Desktop installer is available for x64 only"
        $ok = $false
    }
    else {
        log_success "Processor architecture is x64"
    }
    return $ok
}

function Get-FeatureState {
    param([string]$FeatureName)
    try {
        $feature = Get-WindowsOptionalFeature -Online -FeatureName $FeatureName
        return $feature.State.ToString()
    }
    catch {
        log_error "ERR005: Failed to query feature $FeatureName"
        log_error "ERR005: $_"
        exit 1
    }
}

function Enable-Feature {
    param([string]$FeatureName)
    log_info "Enabling feature: $FeatureName"
    & dism.exe /online /enable-feature /featurename:$FeatureName /all /norestart
    switch ($LASTEXITCODE) {
        0       { log_success "Feature enabled: $FeatureName" }
        3010    { log_success "Feature enabled (reboot needed): $FeatureName" }
        default {
            log_error "ERR006: DISM failed for $FeatureName with exit code $LASTEXITCODE"
            exit 1
        }
    }
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

log_start

# --- Prerequisite: Administrator/SYSTEM ---
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    log_error "ERR001: This script must run as Administrator or SYSTEM"
    log_error "ERR001: Right-click PowerShell > 'Run as administrator'"
    exit 1
}
log_success "Running as Administrator"

# --- Prerequisite: Windows 11 on x64 ---
if (-not (Test-HostPlatform)) {
    exit 1
}

# --- Prerequisite: Virtualization ---
try {
    $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem
    if (-not $computerInfo.HypervisorPresent) {
        log_error "ERR003: Virtualization is not enabled"
        log_error "ERR003: Enable Intel VT-x or AMD-V in BIOS/UEFI settings"
        exit 1
    }
    log_success "Virtualization is enabled"
}
catch {
    log_warning "Could not check virtualization status: $_"
    log_warning "Continuing anyway - DISM will fail if virtualization is missing"
}

# --- Check current feature state ---
$wslState = Get-FeatureState $WSL_FEATURE
$vmState  = Get-FeatureState $VM_FEATURE
log_info "Current state: $WSL_FEATURE = $wslState"
log_info "Current state: $VM_FEATURE = $vmState"

# Already fully enabled - nothing to do
if ($wslState -eq "Enabled" -and $vmState -eq "Enabled") {
    log_success "Both features are already enabled"
    log_success "$SCRIPT_NAME completed - no action needed"
    exit 0
}

# EnablePending - install already ran, just needs reboot
if ($wslState -eq "EnablePending" -or $vmState -eq "EnablePending") {
    log_warning "Features are pending reboot"
    log_warning "$WSL_FEATURE = $wslState"
    log_warning "$VM_FEATURE = $vmState"
    log_info "$SCRIPT_NAME completed - reboot required"
    exit 3010
}

# --- Enable features ---
$needsReboot = $false

Enable-Feature $WSL_FEATURE
if ($LASTEXITCODE -eq 3010) { $needsReboot = $true }

Enable-Feature $VM_FEATURE
if ($LASTEXITCODE -eq 3010) { $needsReboot = $true }

# --- Verify features are now enabled (or pending) ---
$wslStateAfter = Get-FeatureState $WSL_FEATURE
$vmStateAfter  = Get-FeatureState $VM_FEATURE
log_info "After install: $WSL_FEATURE = $wslStateAfter"
log_info "After install: $VM_FEATURE = $vmStateAfter"

$validStates = @("Enabled", "EnablePending")
if ($wslStateAfter -notin $validStates) {
    log_error "ERR007: $WSL_FEATURE is in unexpected state: $wslStateAfter"
    exit 1
}
if ($vmStateAfter -notin $validStates) {
    log_error "ERR007: $VM_FEATURE is in unexpected state: $vmStateAfter"
    exit 1
}

log_success "Both features verified"

# --- Exit with correct code ---
if ($needsReboot -or $wslStateAfter -eq "EnablePending" -or $vmStateAfter -eq "EnablePending") {
    log_info "$SCRIPT_NAME completed - reboot required"
    exit 3010
}

log_success "$SCRIPT_NAME completed"
exit 0
