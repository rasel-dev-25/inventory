# PowerShell equivalent of tool/check_layer_boundaries.sh for Windows.
# Enforces the same import-direction rules described in ARCHITECTURE.md.
$fail = 0

function Check-Layer($layerDir, $pattern, $description) {
    if (-not (Test-Path $layerDir)) { return }
    $matches = Get-ChildItem -Path $layerDir -Recurse -Filter *.dart | Select-String -Pattern $pattern
    if ($matches) {
        Write-Host "VIOLATION: $description"
        $matches | ForEach-Object { Write-Host "$($_.Path):$($_.LineNumber): $($_.Line)" }
        $script:fail = 1
    }
}

# domain/ is pure Dart — must never import Flutter, Drift, Supabase, or GetX.
Check-Layer "lib/domain" "^import '(package:flutter|package:drift|package:supabase|package:get)" "lib/domain/** must not import Flutter, Drift, Supabase, or GetX"

# data/ must not import Flutter widget libraries.
Check-Layer "lib/data" "^import '(package:flutter/(material|cupertino|widgets)\.dart)" "lib/data/** must not import Flutter widget libraries"

# core/ must not import feature modules.
Check-Layer "lib/core" "^import '(package:inventory/features|\.\./\.\./features|\.\./features)" "lib/core/** must not import lib/features/**"

if ($fail -ne 0) {
    Write-Host "One or more architectural layer boundaries were violated. See ARCHITECTURE.md."
    exit 1
}
Write-Host "Layer boundaries OK"