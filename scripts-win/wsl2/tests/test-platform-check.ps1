#!/usr/bin/env pwsh
# File: test-platform-check.ps1
#
# Usage:
#   test-platform-check.ps1 [OPTIONS]
#   test-platform-check.ps1 [-Help]
#
# Purpose:
#   Unit test for Test-HostPlatform (Windows 11 + x64 check) in wsl2 and rancher-desktop install.ps1
#
# Author: Ops Team
# Created: September 2026
#
# Runs anywhere pwsh runs (devcontainer, CI): it reads the function out of each
# install.ps1 without running the script, and calls it with fake build/arch values.
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

$SCRIPT_ID          = "test-platform-check"
$SCRIPT_NAME        = "Platform Check Unit Test"
$SCRIPT_VER         = "0.1.0"
$SCRIPT_DESCRIPTION = "Unit test for the Windows 11 + x64 check in the wsl2 and rancher-desktop installers."
$SCRIPT_CATEGORY    = "TEST"

#------------------------------------------------------------------------------
# CONFIGURATION
#------------------------------------------------------------------------------

# Built with nested Join-Path so the separator is right on Windows and Linux pwsh
$SCRIPTS_WIN_DIR = (Resolve-Path (Join-Path (Join-Path $PSScriptRoot "..") "..")).Path
$TARGET_SCRIPTS  = @(
    (Join-Path (Join-Path $SCRIPTS_WIN_DIR "wsl2") "install.ps1"),
    (Join-Path (Join-Path $SCRIPTS_WIN_DIR "rancher-desktop") "install.ps1")
)
$FUNCTION_NAME   = "Test-HostPlatform"
$TEST_MIN_BUILD  = 22000

# Each case: build, architecture, expected result
$TEST_CASES = @(
    @{ Build = 22000; Arch = "x64";   Expected = $true;  Name = "Windows 11 21H2 on x64" },
    @{ Build = 26100; Arch = "x64";   Expected = $true;  Name = "Windows 11 24H2 on x64" },
    @{ Build = 19045; Arch = "x64";   Expected = $false; Name = "Windows 10 22H2 on x64" },
    @{ Build = 22631; Arch = "ARM64"; Expected = $false; Name = "Windows 11 on ARM64" },
    @{ Build = 19041; Arch = "ARM64"; Expected = $false; Name = "Windows 10 on ARM64" }
)

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

function Get-FunctionText {
    param([string]$ScriptPath, [string]$Name)
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) {
        log_error "ERR001: $ScriptPath has parse errors: $($errors[0].Message)"
        exit 1
    }
    $found = $ast.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $Name
    }, $true)
    if (-not $found -or @($found).Count -ne 1) {
        log_error "ERR002: Expected exactly one function $Name in $ScriptPath"
        exit 1
    }
    return @($found)[0].Extent.Text
}

#------------------------------------------------------------------------------
# MAIN
#------------------------------------------------------------------------------

log_start

$failures = 0

foreach ($script in $TARGET_SCRIPTS) {
    log_info "Testing $FUNCTION_NAME in $script"
    $functionText = Get-FunctionText -ScriptPath $script -Name $FUNCTION_NAME

    # Define the function in this scope, replacing any previous definition
    . ([scriptblock]::Create($functionText))

    foreach ($case in $TEST_CASES) {
        $result = Test-HostPlatform -Build $case.Build -Architecture $case.Arch -MinBuild $TEST_MIN_BUILD 6>$null
        if ($result -eq $case.Expected) {
            log_success "PASS: $($case.Name) -> $result"
        }
        else {
            log_error "ERR003: FAIL: $($case.Name) -> $result (expected $($case.Expected))"
            $failures++
        }
    }
}

if ($failures -gt 0) {
    log_error "ERR003: $failures case(s) failed"
    exit 1
}

log_success "$SCRIPT_NAME completed -- all cases passed"
exit 0
