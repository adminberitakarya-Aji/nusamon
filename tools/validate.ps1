# tools/validate.ps1 — Validasi data JSON NUSAMON
# Jalankan dari folder mana saja:  powershell -File tools\validate.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$errs = @()

function Fail($msg) { $script:errs += $msg }

# --- muat data
try {
    $j = Get-Content "$root\data\nusamons.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    $m = Get-Content "$root\data\moves.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    $t = Get-Content "$root\data\type-chart.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    $it = Get-Content "$root\data\items.json" -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    Write-Host "GAGAL PARSE JSON: $_" -ForegroundColor Red
    exit 1
}

# --- jumlah dasar
if ($j.nusamons.Count -ne 30) { Fail "nusamons != 30 (aktual $($j.nusamons.Count))" }
if (($j.habitatPulau.PSObject.Properties | Measure-Object).Count -ne 30) { Fail "habitatPulau != 30" }
if (($j.detailSpesies.PSObject.Properties | Measure-Object).Count -ne 30) { Fail "detailSpesies != 30" }
if ($t.tipeList.Count -ne 11) { Fail "tipeList != 11" }
if (($t.efektivitas.PSObject.Properties | Measure-Object).Count -ne 11) { Fail "baris efektivitas != 11" }

# --- moves
$dupMoves = $m.moves | Group-Object id | Where-Object { $_.Count -gt 1 }
if ($dupMoves) { Fail ("move id duplikat: " + ($dupMoves.Name -join ', ')) }
foreach ($mv in $m.moves) {
    if ($t.tipeList -notcontains $mv.tipe) { Fail "move $($mv.id): tipe tidak valid ($($mv.tipe))" }
    if ($mv.kategori -eq 'status' -and $null -ne $mv.power) { Fail "move $($mv.id): status harus power=null" }
    if ($mv.kategori -ne 'status' -and $null -eq $mv.power) { Fail "move $($mv.id): serang harus punya power" }
}

# --- nusamons detail
$moveIds = $m.moves.id
$abSet = @('taring_tajam','panen_subur','napas_dalam','pelindung_karang','mata_elang','kulit_tebal','refleks_kilat','cengkeraman_kuat','racun_alami','serbuk_sari','madu_manis','tiruan_suara')
foreach ($n in $j.nusamons) {
    foreach ($s in $n.tahapan) {
        foreach ($tp in $s.tipe) { if ($t.tipeList -notcontains $tp) { Fail "id $($n.id): tipe invalid ($tp)" } }
    }
    if ([string]::IsNullOrWhiteSpace($n.deskripsi)) { Fail "id $($n.id): deskripsi kosong" }
    $id = $n.id.ToString()
    if (-not $j.habitatPulau.$id) { Fail "id $($n.id): habitatPulau hilang" }
    $d = $j.detailSpesies.$id
    if ($null -eq $d) { Fail "id $($n.id): detailSpesies hilang"; continue }
    if ($abSet -notcontains $d.ability) { Fail "id $($n.id): ability invalid ($($d.ability))" }
    if ($d.learnset.Count -lt 4) { Fail "id $($n.id): learnset < 4 move" }
    foreach ($l in $d.learnset) { if ($moveIds -notcontains $l.move) { Fail "id $($n.id): move invalid ($($l.move))" } }
    # skala evolusi menaik
    $sk = @($n.tahapan | ForEach-Object { $_.skala })
    for ($i = 1; $i -lt $sk.Count; $i++) { if ($sk[$i] -le $sk[$i-1]) { Fail "id $($n.id): skala tidak menaik" } }
}

# --- items (Amukan bonus = engine; Teh Herba jenis latihan)
$bonusHarus = @{ amukan = 1.0; amukan_kuat = 1.5; amukan_super = 2.0; amukan_nusantara = 3.0 }
if (($it.items | Measure-Object).Count -ne 5) { Fail "items != 5 (aktual $(($it.items | Measure-Object).Count))" }
$dupItems = $it.items | Group-Object id | Where-Object { $_.Count -gt 1 }
if ($dupItems) { Fail ("item id duplikat: " + ($dupItems.Name -join ', ')) }
foreach ($objek in $it.items) {
    if ($objek.jenis -eq 'amukan') {
        $harus = $bonusHarus[$objek.id]
        if ($null -eq $harus) { Fail "item $($objek.id): id amukan tidak dikenal" }
        elseif ([math]::Abs([double]$objek.bonus - [double]$harus) -gt 0.0001) { Fail "item $($objek.id): bonus $($objek.bonus) != engine $harus" }
        if ($objek.id -eq 'amukan_nusantara') {
            if ($objek.toko) { Fail "amukan_nusantara tidak boleh dijual di toko" }
        } else {
            if (-not $objek.toko) { Fail "item $($objek.id): harus tersedia di toko" }
            if ([int]$objek.harga -le 0) { Fail "item $($objek.id): harga harus > 0" }
        }
    } elseif ($objek.jenis -eq 'latihan') {
        if ($null -ne $objek.bonus) { Fail "item $($objek.id): bonus harus null" }
        if (-not $objek.toko) { Fail "item $($objek.id): harus dijual di toko" }
        if ([int]$objek.harga -le 0) { Fail "item $($objek.id): harga harus > 0" }
    } else {
        Fail "item $($objek.id): jenis tidak dikenal ($($objek.jenis))"
    }
}

# --- hasil
if ($errs.Count -eq 0) {
    Write-Host "VALIDASI LOLOS: data NUSAMON konsisten (30 spesies / 25 move / 11 tipe / 5 item)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "VALIDASI GAGAL:" -ForegroundColor Red
    $errs | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
    exit 1
}
