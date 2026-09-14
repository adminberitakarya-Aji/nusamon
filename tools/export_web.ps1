# tools/export_web.ps1 - Export build Web (HTML5) NUSAMON (ADR-04: PC + Web)
# Jalankan: powershell -File tools\export_web.ps1
# Output:   build/web/index.html (+ .wasm/.pck) - siap di-host statis.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

# --- 1. cari Godot (pola sama dengan run_tests.ps1)
$exe = $null
$cmd = Get-Command godot -ErrorAction SilentlyContinue
if ($cmd) {
    $exe = $cmd.Source
} else {
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
    exit 1
}
Write-Host "Godot: $exe"

# --- 2. cek export templates (versi dari nama exe, fallback: scan folder templates)
$versi = ""
if ($exe -match 'Godot_v([0-9.]+)-([A-Za-z]+)') {
    $versi = "$($Matches[1]).$($Matches[2])"
}
$tplRoot = Join-Path $env:APPDATA 'Godot\export_templates'
$tplDir = $null
$kandidatDir = @()
if ($versi -ne "" -and (Test-Path (Join-Path $tplRoot $versi))) {
    $kandidatDir += Join-Path $tplRoot $versi
}
if (Test-Path $tplRoot) {
    $kandidatDir += Get-ChildItem $tplRoot -Directory -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty FullName
}
foreach ($d in $kandidatDir | Select-Object -Unique) {
    if (Test-Path (Join-Path $d 'web_nothreads_release.zip')) {
        $tplDir = $d
        break
    }
}
if ($null -eq $tplDir) {
    Write-Host "Export templates Web tidak ditemukan di $tplRoot" -ForegroundColor Red
    Write-Host "Pasang lewat Godot: Editor -> Manage Export Templates -> Download and Install,"
    Write-Host "atau unduh manual dari godotengine.org/download (tpz untuk versi Godot yang dipakai)."
    exit 1
}
if ($versi -ne "" -and (Split-Path -Leaf $tplDir) -ne $versi) {
    Write-Host "PERINGATAN: versi templates ($((Split-Path -Leaf $tplDir))) berbeda dari Godot ($versi)." -ForegroundColor Yellow
}
Write-Host "Templates: $tplDir"

# --- 3. export release Web
$outDir = Join-Path $root 'build\web'
New-Item $outDir -ItemType Directory -Force | Out-Null
& $exe --headless --path $root --export-release "Web" (Join-Path $outDir 'index.html')
if ($LASTEXITCODE -ne 0) {
    Write-Host "EXPORT GAGAL (exit $LASTEXITCODE)." -ForegroundColor Red
    exit 1
}

# --- 4. ringkasan hasil
$files = Get-ChildItem $outDir -File
$total = ($files | Measure-Object -Property Length -Sum).Sum
Write-Host ""
Write-Host "EXPORT WEB BERHASIL -> build/web" -ForegroundColor Green
$files | ForEach-Object { Write-Host (" - {0} ({1:N0} bytes)" -f $_.Name, $_.Length) }
Write-Host ("Total: {0:N0} bytes - host folder build/web secara statis (mis. GitHub Pages/Netlify)." -f $total)
exit 0