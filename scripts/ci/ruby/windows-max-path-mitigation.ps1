#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "=== Windows MAX_PATH mitigation setup ===" -ForegroundColor Cyan

# Create short path directories for build
New-Item -ItemType Directory -Path "C:\t" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\b" -Force | Out-Null
New-Item -ItemType Directory -Path "C:\g" -Force | Out-Null

# Also create the fallback directory used by extconf.rb
New-Item -ItemType Directory -Path "C:\kz-build" -Force | Out-Null

# Configure bundler to use shorter path
Push-Location packages/ruby
bundle config set path "C:\b"
bundle config set no_prune true
Pop-Location

# Export env vars for subsequent steps
Add-Content -Path $env:GITHUB_ENV -Value "CARGO_TARGET_DIR=C:\t"
Add-Content -Path $env:GITHUB_ENV -Value "BUNDLE_PATH=C:\b"
Add-Content -Path $env:GITHUB_ENV -Value "GEM_HOME=C:\g"

# Also set OUT_DIR to match CARGO_TARGET_DIR for consistency
Add-Content -Path $env:GITHUB_ENV -Value "OUT_DIR=C:\t"

# Set BUNDLE_GEMFILE using PowerShell-resolved path to avoid bash path mangling
# On Windows, github.workspace paths like D:/a/... get mangled to D:/d/a/... in bash shells
$gemfilePath = Join-Path $PWD.Path "packages\ruby\Gemfile"
Add-Content -Path $env:GITHUB_ENV -Value "BUNDLE_GEMFILE=$gemfilePath"

Write-Host "Windows MAX_PATH mitigation paths configured:"
Write-Host "  CARGO_TARGET_DIR: C:\t"
Write-Host "  OUT_DIR: C:\t"
Write-Host "  BUNDLE_PATH: C:\b"
Write-Host "  GEM_HOME: C:\g"
Write-Host "  BUNDLE_GEMFILE: $gemfilePath"
Write-Host "  Fallback build dir: C:\kz-build"
