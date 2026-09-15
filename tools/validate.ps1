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
    $w = Get-Content "$root\data\world.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    $tr = Get-Content "$root\data\trainers.json" -Raw -Encoding UTF8 | ConvertFrom-Json
    $au = Get-Content "$root\data\audio.json" -Raw -Encoding UTF8 | ConvertFrom-Json
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

# --- items (Amukan bonus = engine; Teh Herba jenis latihan; kunci = gate dunia)
$bonusHarus = @{ amukan = 1.0; amukan_kuat = 1.5; amukan_super = 2.0; amukan_nusantara = 3.0 }
if (($it.items | Measure-Object).Count -ne 9) { Fail "items != 9 (aktual $(($it.items | Measure-Object).Count))" }
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
    } elseif ($objek.jenis -eq 'kunci') {
        if ($objek.toko) { Fail "item $($objek.id): item kunci tidak boleh dijual di toko" }
        if ($null -ne $objek.harga) { Fail "item $($objek.id): harga kunci harus null" }
        if ([string]::IsNullOrWhiteSpace($objek.ket)) { Fail "item $($objek.id): ket kosong" }
    } else {
        Fail "item $($objek.id): jenis tidak dikenal ($($objek.jenis))"
    }
}

# --- world (6 pulau + Laut Nusantara — Fase 5)
$locIds = $w.lokasi.id
if ($w.lokasi.Count -ne 28) { Fail "world: lokasi != 28 (aktual $($w.lokasi.Count))" }
if ($locIds -notcontains $w.lokasi_awal) { Fail "world: lokasi_awal tidak valid ($($w.lokasi_awal))" }
$dupLoc = $w.lokasi | Group-Object id | Where-Object { $_.Count -gt 1 }
if ($dupLoc) { Fail ("world: id lokasi duplikat: " + ($dupLoc.Name -join ', ')) }
$namaPulau = @($w.pulau)
if ($namaPulau.Count -ne 7) { Fail "world: daftar pulau != 7 (aktual $($namaPulau.Count))" }
$kunciIds = @($it.items | Where-Object { $_.jenis -eq 'kunci' } | ForEach-Object { $_.id })
$spIds = $j.nusamons.id
$legendaryIds = @($j.nusamons | Where-Object { $_.rarity -eq 'legendary' } | ForEach-Object { $_.id })
foreach ($k in $w.koneksi) {
    if ($locIds -notcontains $k.dari) { Fail "world: koneksi.dari tidak valid ($($k.dari))" }
    if ($locIds -notcontains $k.ke) { Fail "world: koneksi.ke tidak valid ($($k.ke))" }
    $balik = $w.koneksi | Where-Object { $_.dari -eq $k.ke -and $_.ke -eq $k.dari }
    if (-not $balik) { Fail "world: koneksi $($k.dari)->$($k.ke) tidak simetris" }
    if ($null -ne $k.gate) {
        if ($k.gate.jenis -eq 'lencana') {
            if ([int]$k.gate.id -lt 1 -or [int]$k.gate.id -gt 8) { Fail "world: gate lencana id di luar 1..8" }
        } elseif ($k.gate.jenis -eq 'item') {
            if ($kunciIds -notcontains $k.gate.id) { Fail "world: gate item id tidak dikenal ($($k.gate.id))" }
            if ([string]::IsNullOrWhiteSpace($k.gate.nama)) { Fail "world: gate item $($k.gate.id) tanpa nama (teks UI)" }
        } else { Fail "world: gate jenis tidak dikenal ($($k.gate.jenis))" }
    }
}
foreach ($l in $w.lokasi) {
    if ($namaPulau -notcontains $l.pulau) { Fail "world $($l.id): pulau tidak valid ($($l.pulau))" }
    if ($l.jenis -eq 'rute' -and ($l.encounters | Measure-Object).Count -eq 0) { Fail "world $($l.id): rute tanpa encounter" }
    if ($l.jenis -ne 'rute' -and ($l.encounters | Measure-Object).Count -gt 0) { Fail "world $($l.id): kota/desa/landmark tidak boleh punya encounter" }
    foreach ($e in $l.encounters) {
        if ($spIds -notcontains [int]$e.spesies) { Fail "world $($l.id): spesies encounter tidak valid ($($e.spesies))" }
        if (($j.habitatPulau."$([int]$e.spesies)") -notcontains $l.pulau) { Fail "world $($l.id): spesies $($e.spesies) tidak berhabitat di $($l.pulau)" }
        if ([double]$e.bobot -le 0) { Fail "world $($l.id): bobot encounter harus > 0" }
        if ([int]$e.level_min -gt [int]$e.level_max) { Fail "world $($l.id): level_min > level_max" }
        if ([int]$e.level_max -gt 60) { Fail "world $($l.id): level_max di luar jangkauan game" }
    }
    if ($l.jenis -eq 'rute') {
        if ($null -eq $l.peluang_encounter) { Fail "world $($l.id): rute tanpa peluang_encounter" }
        elseif ([double]$l.peluang_encounter -le 0 -or [double]$l.peluang_encounter -gt 1) { Fail "world $($l.id): peluang_encounter harus 0..1 (aktual $($l.peluang_encounter))" }
    }
    foreach ($poi in $l.tempat) {
        if ($null -ne $poi.aksi -and @('pilih_starter', 'rival', 'pulihkan', 'toko', 'tiket', 'legendary', 'liga', 'starter_bonus') -notcontains $poi.aksi) { Fail "world $($l.id): aksi POI tidak dikenal ($($poi.aksi))" }
        if ($poi.aksi -eq 'tiket') {
            if ($kunciIds -notcontains $poi.item) { Fail "world $($l.id): POI tiket item tidak valid ($($poi.item))" }
            if ([int]$poi.syarat_lencana -lt 1 -or [int]$poi.syarat_lencana -gt 8) { Fail "world $($l.id): POI tiket syarat_lencana di luar 1..8" }
        }
        if ($poi.aksi -eq 'legendary') {
            if ($legendaryIds -notcontains [int]$poi.spesies) { Fail "world $($l.id): POI legendary bukan spesies legendary ($($poi.spesies))" }
            if ([int]$poi.level -lt 1 -or [int]$poi.level -gt 100) { Fail "world $($l.id): POI legendary level tidak valid" }
            if ($null -ne $poi.item -and $kunciIds -notcontains $poi.item) { Fail "world $($l.id): POI legendary item tidak valid ($($poi.item))" }
            if ($null -ne $poi.syarat_lencana -and ([int]$poi.syarat_lencana -lt 1 -or [int]$poi.syarat_lencana -gt 8)) { Fail "world $($l.id): POI legendary syarat_lencana di luar 1..8" }
        }
        if ($null -ne $poi.dialog -and ($poi.dialog | Measure-Object).Count -lt 1) { Fail "world $($l.id): dialog POI kosong" }
        if ($null -ne $poi.dialog -and (($poi.dialog | ForEach-Object { $_.Trim() }) -contains '')) { Fail "world $($l.id): ada baris dialog kosong" }
    }
}

# --- trainers (gym — Fase 3 langkah 3)
$dupTr = $tr.trainers | Group-Object id | Where-Object { $_.Count -gt 1 }
if ($dupTr) { Fail ("trainer id duplikat: " + ($dupTr.Name -join ', ')) }
$badgeIds = @()
$ligaUrutan = @()
$adaJuara = 0
	foreach ($t in $tr.trainers) {
    $jenis = if ($null -ne $t.jenis) { $t.jenis } else { 'gym' }
    if ($jenis -eq 'gym') {
        if ($locIds -notcontains $t.gym.kota) { Fail "trainer $($t.id): gym.kota tidak valid ($($t.gym.kota))" }
        if ([int]$t.gym.id -lt 1 -or [int]$t.gym.id -gt 8) { Fail "trainer $($t.id): gym.id di luar 1..8" }
        $badgeIds += [int]$t.gym.id
    } elseif ($jenis -eq 'rival') {
        if ($null -ne $t.gym) { Fail "trainer $($t.id): rival tidak boleh punya gym" }
        if ($null -ne $t.lencana) { Fail "trainer $($t.id): rival tidak boleh punya lencana" }
    } elseif ($jenis -eq 'liga') {
        if ($null -ne $t.gym) { Fail "trainer $($t.id): liga tidak boleh punya gym" }
        if ($null -ne $t.lencana) { Fail "trainer $($t.id): liga tidak boleh punya lencana" }
        if ([int]$t.urutan -lt 1 -or [int]$t.urutan -gt 4) { Fail "trainer $($t.id): liga urutan di luar 1..4" }
        $ligaUrutan += [int]$t.urutan
    } elseif ($jenis -eq 'juara') {
        if ($null -ne $t.gym) { Fail "trainer $($t.id): juara tidak boleh punya gym" }
        if ($null -ne $t.lencana) { Fail "trainer $($t.id): juara tidak boleh punya lencana" }
        if ($null -ne $t.urutan) { Fail "trainer $($t.id): juara tidak boleh punya urutan" }
        $adaJuara++
    } else { Fail "trainer $($t.id): jenis tidak dikenal ($jenis)" }
    if (($t.tim | Measure-Object).Count -lt 1 -or ($t.tim | Measure-Object).Count -gt 6) { Fail "trainer $($t.id): tim harus 1..6 mon" }
    $spSeen = @()
    foreach ($m in $t.tim) {
        $isCounter = ($null -ne $m.counter_starter -and $m.counter_starter)
        if ($isCounter) {
            if ([int]$m.spesies -ne 0) { Fail "trainer $($t.id): counter_starter harus spesies=0" }
        } else {
            if ($spIds -notcontains [int]$m.spesies) { Fail "trainer $($t.id): spesies tidak valid ($($m.spesies))" }
            # duplikat spesies hanya dibolehkan bila tahapnya berbeda (mis. Ular Kecil + Ular Raksasa)
            $kunciTim = "$([int]$m.spesies)@$(if ($null -ne $m.tahap) { [int]$m.tahap } else { 0 })"
            if ($spSeen -contains $kunciTim) { Fail "trainer $($t.id): entri tim duplikat ($($m.spesies) tahap sama)" }
            $spSeen += $kunciTim
        }
        if ([int]$m.level -lt 1 -or [int]$m.level -gt 100) { Fail "trainer $($t.id): level di luar 1..100" }
        if ($null -ne $m.tahap -and ([int]$m.tahap -lt 0 -or [int]$m.tahap -gt 2)) { Fail "trainer $($t.id): tahap di luar 0..2" }
    }
    if ([string]::IsNullOrWhiteSpace($t.dialog.intro)) { Fail "trainer $($t.id): dialog.intro kosong" }
    if ([string]::IsNullOrWhiteSpace($t.dialog.menang_pemain)) { Fail "trainer $($t.id): dialog.menang_pemain kosong" }
    if ([string]::IsNullOrWhiteSpace($t.dialog.kalah_pemain)) { Fail "trainer $($t.id): dialog.kalah_pemain kosong" }
    if ([int]$t.hadiah_uang -lt 0) { Fail "trainer $($t.id): hadiah_uang negatif" }
    if ($jenis -eq 'gym' -and [string]::IsNullOrWhiteSpace($t.lencana.nama)) { Fail "trainer $($t.id): lencana.nama kosong" }
}
if ($badgeIds.Count -ne ($badgeIds | Sort-Object -Unique).Count) { Fail "trainers: id gym/lencana duplikat antar trainer" }
if (($badgeIds | Sort-Object) -join ',' -ne (@(1..8) -join ',')) { Fail "trainers: lencana 1..8 tidak lengkap (ada $(($badgeIds | Sort-Object) -join ','))" }
if ($ligaUrutan.Count -ne ($ligaUrutan | Sort-Object -Unique).Count) { Fail "trainers: urutan liga duplikat" }
if (($ligaUrutan | Sort-Object) -join ',' -ne (@(1..4) -join ',')) { Fail "trainers: Elite Empat tidak lengkap (ada $(($ligaUrutan | Sort-Object) -join ','))" }
if ($adaJuara -ne 1) { Fail "trainers: harus tepat 1 juara (ada $adaJuara)" }

# --- audio (Fase 5 langkah 5) — SSOT id/file/volume; placeholder .wav wajib ada
$dupAu = @($au.lagu + $au.sfx) | Group-Object id | Where-Object { $_.Count -gt 1 }
if ($dupAu) { Fail ("audio: id duplikat: " + ($dupAu.Name -join ', ')) }
foreach ($l in $au.lagu) {
    if (@('bgm', 'jingle', 'sting') -notcontains $l.jenis) { Fail "audio $($l.id): jenis lagu tidak dikenal ($($l.jenis))" }
    if ([double]$l.volume -le 0 -or [double]$l.volume -gt 1) { Fail "audio $($l.id): volume di luar 0..1" }
    if (-not (Test-Path "$root\$($l.file)")) { Fail "audio $($l.id): file tidak ditemukan ($($l.file))" }
}
foreach ($s in $au.sfx) {
    if ($s.jenis -ne 'sfx') { Fail "audio $($s.id): sfx harus jenis 'sfx' (ada $($s.jenis))" }
    if ([double]$s.volume -le 0 -or [double]$s.volume -gt 1) { Fail "audio $($s.id): volume di luar 0..1" }
    if (-not (Test-Path "$root\$($s.file)")) { Fail "audio $($s.id): file tidak ditemukan ($($s.file))" }
}

# --- hasil
if ($errs.Count -eq 0) {
    Write-Host "VALIDASI LOLOS: data NUSAMON konsisten (30 spesies / 25 move / 11 tipe / 9 item / world 28 lokasi 6 pulau+laut / trainer 8 gym + liga + juara / audio 17 file)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "VALIDASI GAGAL:" -ForegroundColor Red
    $errs | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
    exit 1
}
