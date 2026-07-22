# Quick pre-run guard to avoid parser regressions.
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/verify_before_run.ps1
#
# What it does:
# 1) Always analyzes critical files that were recently edited heavily.
# 2) Automatically analyzes changed Dart files from git diff.
# 3) Fails only on analyzer errors (not infos/warnings).

$ErrorActionPreference = 'Stop'
Push-Location (Split-Path -Parent $PSScriptRoot)
Push-Location .

try {
  Write-Host 'Running analyzer checks...' -ForegroundColor Cyan

  $criticalFiles = @(
    'lib/features/home/widgets/taameem_action_buttons.dart',
    'lib/features/upload/screens/camera_screen.dart'
  )

  foreach ($file in $criticalFiles) {
    if (Test-Path $file) {
      Write-Host "Analyzing critical file: $file" -ForegroundColor DarkCyan
      flutter analyze --no-fatal-infos --no-fatal-warnings $file
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
  }

  $changedDartFiles = @()
  $gitExists = Get-Command git -ErrorAction SilentlyContinue
  if ($null -ne $gitExists) {
    $changedDartFiles = git diff --name-only -- '*.dart' | Where-Object { $_ -and (Test-Path $_) }
  }

  if ($changedDartFiles.Count -gt 0) {
    Write-Host 'Analyzing changed Dart files from git diff...' -ForegroundColor DarkCyan
    foreach ($file in $changedDartFiles) {
      Write-Host "  - $file"
      flutter analyze --no-fatal-infos --no-fatal-warnings $file
      if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
  } else {
    Write-Host 'No changed Dart files detected in git diff.' -ForegroundColor DarkGray
  }

  Write-Host 'Analyzer checks passed (no error-level diagnostics).' -ForegroundColor Green
} finally {
  Pop-Location
  Pop-Location
}
