# tools/run_tests.ps1 — jalankan tes headless prototipe battle NUSAMON
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

$exe = $null
$cmd = Get-Command godot -ErrorAction SilentlyContinue
if ($cmd) {
    $exe = $cmd.Source
} else {
    # cari di lokasi umum (kedalaman terbatas agar cepat)
    $kandidat = @()
    foreach ($dir in @('C:\Program Files', 'C:\Program Files (x86)', "$env:LOCALAPPDATA\Programs", 'D:\')) {
        $kandidat += Get-ChildItem $dir -Recurse -Depth 2 -Filter 'Godot*.exe' -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName
    }
    $kandidat = $kandidat | Where-Object { $_ -notmatch 'console' } | Select-Object -First 1
    if ($kandidat) { $exe = $kandidat }
}

if (-not $exe) {
    Write-Host "Godot tidak ditemukan." -ForegroundColor Red
    Write-Host "Instal Godot 4 lalu jalankan manual: godot --headless --path `"$root`" --script game/tests/test_battle.gd"
    exit 1
}

Write-Host "Godot: $exe"
& $exe --headless --path $root --script game/tests/test_battle.gd
exit $LASTEXITCODE
