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
    foreach ($dir in @('C:\Program Files', 'C:\Program Files (x86)', "$env:LOCALAPPDATA\Programs", 'C:\Tools', "$env:USERPROFILE\Desktop", "$env:USERPROFILE\Downloads", 'D:\')) {
        $kandidat += Get-ChildItem $dir -Recurse -Depth 2 -Filter 'Godot*.exe' -File -ErrorAction SilentlyContinue |
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
$gagal = $false
foreach ($tes in @('game\tests\test_battle.gd', 'game\tests\test_catch_exp.gd', 'game\tests\test_inventori.gd', 'game\tests\test_tim.gd', 'game\tests\test_nusadex.gd', 'game\tests\test_ability.gd', 'game\tests\test_latihan_simpan.gd', 'game\tests\test_world.gd', 'game\tests\test_encounter.gd', 'game\tests\test_trainer.gd', 'game\tests\test_battle_trainer.gd', 'game\tests\test_env.gd', 'game\tests\test_scene.gd')) {
    Write-Host ""
    Write-Host "--- Menjalankan: $tes ---"
    # Start-Process dipakai agar ExitCode terbaca andal di semua lingkungan
    # (invokasi & langsung bisa meninggalkan $LASTEXITCODE null).
    $proc = Start-Process -FilePath $exe -ArgumentList @('--headless', '--path', $root, '--script', $tes) -Wait -PassThru -NoNewWindow
    Write-Host "(exit code: $($proc.ExitCode))"
    if ($proc.ExitCode -ne 0) { $gagal = $true }
}
if ($gagal) {
    Write-Host "ADA TES GAGAL." -ForegroundColor Red
    exit 1
}
exit 0
