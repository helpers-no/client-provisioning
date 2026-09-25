#!/usr/bin/env pwsh
# File: test-version-pin.ps1
#
# Usage:
#   test-version-pin.ps1 [OPTIONS]
#   test-version-pin.ps1 [-Help]
#
# Purpose:
#   Checks that detect.ps1 and install.ps1 pin the same Rancher Desktop version
#
# Author: Ops Team
# Created: September 2026
#
# Runs anywhere pwsh runs (devcontainer, CI). It reads both values out of the
# scripts with the PowerShell parser, without running them.
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

$SCRIPT_ID          = "test-version-pin"
$SCRIPT_NAME        = "Rancher Version Pin Test"
$SCRIPT_VER         = "0.1.0"
$SCRIPT_DESCRIPTION = "Checks that detect.ps1 and install.ps1 pin the same Rancher Desktop version."
$SCRIPT_CATEGORY    = "TEST"

#------------------------------------------------------------------------------
# CONFIGURATION
#------------------------------------------------------------------------------

# Built with nested Join-Path so the separator is right on Windows and Linux pwsh
$PACKAGE_DIR  = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$INSTALL_FILE = Join-Path $PACKAGE_DIR "install.ps1"
$DETECT_FILE  = Join-Path $PACKAGE_DIR "detect.ps1"
$INSTALL_VAR  = "RANCHER_VERSION"
$DETECT_VAR   = "MIN_RANCHER_VERSION"

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

function Get-AssignedString {
    param([string]$ScriptPath, [string]$VariableName)
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) {
        log_error "ERR001: $ScriptPath has parse errors: $($errors[0].Message)"
        exit 1
    }
    $found = @($ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
        $node.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and
        $node.Left.VariablePath.UserPath -eq $VariableName
    }, $true))
    if ($found.Count -ne 1) {
        log_error "ERR002: Expected exactly one assignment to `$$VariableName in $ScriptPath, found $($found.Count)"
        exit 1
    }
    return $found[0].Right.Extent.Text.Trim('"', "'", ' ')
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

log_start

$pinned   = Get-AssignedString -ScriptPath $INSTALL_FILE -VariableName $INSTALL_VAR
$detected = Get-AssignedString -ScriptPath $DETECT_FILE  -VariableName $DETECT_VAR

log_info "install.ps1  `$$INSTALL_VAR = $pinned"
log_info "detect.ps1   `$$DETECT_VAR = $detected"

if ($pinned -ne $detected) {
    log_error "ERR003: The versions differ. Intune would detect a PC as up to date while install.ps1 installs another version"
    exit 1
}

log_success "$SCRIPT_NAME completed -- both pin $pinned"
exit 0
