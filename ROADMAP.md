# ROADMAP NUSAMON — Status Pengerjaan Detail (v0.1)

> **Dokumen ini = satu-satunya sumber status progres granular** (single source of truth).
> Rencana makro ada di `docs/GDD.md` §9; dokumen ini menguraikannya menjadi langkah konkret,
> kriteria selesai (DoD), backlog teknis, dan riwayat keputusan per langkah.
> Wajib diperbarui di setiap commit berfitur — jangan biarkan dokumen ini mati.

**Legenda status:** ✅ selesai · 🔨 berjalan/parsial · ⬜ belum mulai · 🧊 sengaja ditunda (backlog)

---

## 1. Peta Fase (dari GDD §9)

| Fase | Status | Ringkasan | Kriteria Selesai (DoD) |
|--:|--------|-----------|------------------------|
| 0 — Desain | ✅ **Selesai** | GDD, roster 30 spesies, type chart 11×11, base stats, data JSON tervalidasi | 9 dokumen desain + 3 file data JSON + `validate.ps1` lolos |
| 1 — Prototipe Battle | ✅ **Selesai** | Battle 1v1, tangkap, EXP/evolusi, UI scene, PP, tahap stat, tes headless | Battle end-to-end (serang/tangkap/kabur) + EXP + evolusi + **78 asersi hijau (3 suite)** + UI terverifikasi (simulasi headless; inspeksi visual disarankan saat mulai Fase 2) |
| 2 — Catch & Nusadex | ✅ **Selesai** (catatan: pratinjau model butuh aset Blender — D-1) | Inventori, tim/partai, switch, Nusadex, ability, Latihan, save/load | Tangkap masuk tim, Nusadex terisi, ability & PP aktif, Latihan & save/load aktif |
| 3 — World & Gym pertama | 🔨 **Berjalan** | World map Jawa, G1 Normal (Bu Sari) | Battle trainer + lencana G1 |
| 4 — Vertical Slice | ⬜ Belum mulai | MVP end-to-end: Jawa + G1 + G2 + rival + Nusadex | Main dari Desa Sumberrejo sampai lencana G2 tanpa jebol (GDD §8) |
| 5 — Produksi konten penuh | ⬜ Belum mulai | 30 spesies, 6 pulau, 8 gym, Liga Nusantara, story | Tamat end-to-end + Nusadex 100% |

---

## 2. Detail per Fase

### Fase 0 — Desain ✅

| Langkah | Status | Referensi |
|---------|:------:|-----------|
| GDD utama (visi, sistem, loop, roadmap, risiko) | ✅ | commit `917f008` (2026-09-13) |
| Roster 30 spesies + type chart 11×11 + base stats + world region + gameplay depth + Nusadex + ekspansi | ✅ | `917f008` |
| Data machine-readable: `nusamons.json` (30 spesies), `moves.json` (25 move), `type-chart.json` (11 tipe) | ✅ | `917f008` |
| Validasi data otomatis (`tools/validate.ps1`) | ✅ | `917f008` — status: LOLOS |
| Keputusan teknis terkunci (ADR-01…07) | ✅ | `36f78df` |

### Fase 1 — Prototipe Battle ✅ (Selesai)

**Kerangka & engine logika**

| Langkah | Status | Referensi |
|---------|:------:|-----------|
| Proyek Godot 4 di root repo (`res://` = path repo) | ✅ | `36f78df` |
| Loader data JSON (`NusamonData`) + lookup spesies/stat tahap | ✅ | `66968a7` |
| Rumus damage Gen-V (STAB ×1.5, krit 6.25%, random 0.85–1.00) | ✅ | `66968a7` |
| Efektivitas tipe (dual-type: perkalian kolom, kebal = 0) | ✅ | `66968a7` |
| Urutan giliran (prioritas move → SPE) | ✅ | `66968a7` |
| Status: luka bakar, racun, kelumpuhan, tidur (2–4 giliran) | ✅ | `66968a7` |
| Instans battle: stat HP & non-HP sesuai rumus runtime docs | ✅ | `4bc8452` |

**Sistem tangkap, EXP, evolusi**

| Langkah | Status | Referensi |
|---------|:------:|-----------|
| Formula tangkap Gen-V (a ≥ 255 = pasti; 4 shake check) | ✅ | `f9502c7` |
| Bonus ball (Amukan 1.0/1.5/2.0/3.0) + bonus status (tidur/racun ×2, lumpuh ×1.5) | ✅ | `f9502c7` |
| EXP kurva medium-fast (L³), gain `floor(yield×lv/7)×1.5` trainer | ✅ | `f9502c7` |
| Naik level + trigger evolusi multi-tahap + bonus HP evolusi | ✅ | `f9502c7` |

**UI & runtime**

| Langkah | Status | Referensi |
|---------|:------:|-----------|
| Battle scene programatik (panel, HP bar, log, menu) | ✅ | `f9502c7` |
| Fitur lempar Amukan di UI (4 jenis ball) + menu disable saat turn | ✅ | `c7fad96` |
| Fix deadlock: status di akhir giliran bisa mengakhiri battle | ✅ | `c7fad96` |
| Fix kelumpuhan di-rol dua kali per giliran | ✅ | `4629f5c` |

**Kualitas & tooling**

| Langkah | Status | Referensi |
|---------|:------:|-----------|
| Tes headless `test_battle.gd` (42 asersi) | ✅ | `66968a7`, diperbaiki `4bc8452`, diperluas `4629f5c` |
| Tes headless `test_catch_exp.gd` (23 asersi) | ✅ | `f9502c7`, asersi diperbaiki `4bc8452` |
| Tes scene headless `test_scene.gd` (13 asersi): UI terbangun + simulasi battle penuh | ✅ | `4629f5c` |
| Runner `tools/run_tests.ps1` menjalankan 3 suite + exit code andal | ✅ | `4389f5f`, diperluas `4629f5c` |
| Upgrade proyek ke Godot 4.7 + verifikasi runtime | ✅ | `4389f5f` — 52 asersi hijau (0 gagal) |
| Verifikasi parse JSON (file dengan BOM) di Godot 4.7.2 | ✅ | `4389f5f` — ketiga JSON terbaca normal |
| Sinkronisasi stat runtime kode ↔ `docs/base-stats.md` | ✅ | `4bc8452` |

**Penutup Fase 1 (semua ✅ — commit `4629f5c`):**

| Langkah | Status | Catatan |
|---------|:------:|---------|
| Sistem tahap stat (buff/debuff, faktor ×tahap, batas ±6) + efek `buff_atk`/`buff_def`/`debuff_atk`/`heal_50` | ✅ | keputusan: implement minimal, bukan tunda |
| Sistem PP (field `poin`) + Meronta (fallback saat semua PP habis) + tombol move disable saat PP 0 | ✅ | PP berkurang walau move meleset (konvensi Pokémon) |
| Fix: efekData hanya diterapkan bila serangan kena | ✅ | temuan saat implementasi B-1 — sebelumnya efek jalan walau meleset |
| Fix kelumpuhan di-rol dua kali per giliran (C-2) | ✅ | cek lumpuh cukup saat mon mencoba beraksi |
| Fix kosmetik log tangkap: "tertangkap" (C-7) | ✅ | bukan lagi "menang" |
| Verifikasi UI: simulasi battle penuh headless via `test_scene.gd` | ✅ | inspeksi visual di editor disarankan saat mulai Fase 2 |

### Fase 2 — Catch & Nusadex ✅ (Selesai)

| Langkah | Status |
|---------|:------:|
| Inventori Amukan terbatas: uang (Rupiah, awal Rp 3.000) + stok (awal 5) + toko + pengurangan stok saat lempar — data `items.json` + kelas `Inventori` + UI toko | ✅ `9fd0a9c` |
| Tim/partai (maks. 6) + hasil tangkap masuk tim — kelas `Tim`, mon aktif persisten (EXP/evolusi tersimpan), pemulihan awal battle, panel tim | ✅ `ea7b214` |
| Switch/tukar Nusamon saat battle (GDD §4.1) — menu ganti, ganti = 1 giliran (lawan menyerang balik), mon aktif/pingsan nonaktif | ✅ `40c3987` |
| Nusadex: record lihat/tangkap, layar daftar + detail (`docs/nusadex.md`) — kelas `Nusadex`, overlay UI, field `deskripsi` 30 spesies kini terisi di `nusamons.json` | ✅ `40c3987` |
| Ability engine: 12 ability dari `docs/gameplay-depth.md` — `AbilityEngine` + status `terpikat` | ✅ `3637879` |
| Move status buff/debuff/heal + stat stage (naik/turun tahap) | ✅ `4629f5c` (dikerjakan di penutupan Fase 1) |
| Sistem PP move (`poin` di `moves.json`) — PP per move + Meronta | ✅ `4629f5c` (dikerjakan di penutupan Fase 1) |
| Latihan (EV-lite): poin per battle, cap 50/25, konversi 4:1, item reset — Teh Herba (Rp 500) di toko | ✅ `2a6dd71` |
| Penyimpanan (save/load) — format **JSON v1** `user://simpanan.json`: uang, stok, tim (level/HP/status/exp/latihan), nusadex; tombol 💾/📂 + auto-load & auto-save | ✅ `2a6dd71` |
| Impor model tahap 2/3 + tampil di battle — runtime selesai (`path_model`, pratinjau SubViewport, fallback diam); **aset .glb menunggu Blender** (D-1) | 🔨 runtime `2a6dd71` |

### Fase 3 — World & Gym pertama 🔨 (Berjalan)

| Langkah | Status |
|---------|:------:|
| World map Jawa ringkas (GDD §8): Desa Sumberrejo → Rute 1 → Kota Harapan → Rute 2 → Kota Arunika | ✅ `data/world.json` (5 lokasi + koneksi dua arah + gate Lencana G1 + tabel encounter) · `WorldEngine` (traversal/gate, static headless) · `Progres` (lokasi + lencana, static store) · `world_scene.tscn` (UI programatik) · tombol 🌍 DUNIA di battle scene · 46 asersi hijau (`test_world`) `9da1b3d` |
| Sistem encounter liar per rute (`habitatPulau` + bobot rarity) | ✅ `EncounterSystem` (pool tabel khas + pool turunan habitat × bobot rarity gameplay-depth §4; starter/legendary tidak liar) · `peluang_encounter` per rute di `world.json` (0.4/0.45) · tombol 🔍 JELAJAHI di rute → antrean → battle liar · 49 asersi hijau (`test_encounter`) `9da1b3d` |
| Gym G1 Normal — Bu Sari (Monyet Kecil Lv.8, Ayam Jantan Lv.10) | ✅ `data/trainers.json` (tim 2 mon, dialog intro/menang/kalah, hadiah Rp 1.200, Lencana Harapan) · `TrainerEngine` (cari/trainer_di_kota/buat_tim/tim_teks/lencana) · panel gym di world scene (⌛ tantang = langkah 4) · 29 asersi hijau (`test_trainer`) `9da1b3d` |
| Battle trainer (multiplikator EXP ×1.5 sudah siap di engine) | ⬜ |
| Lencana + progresi | ⬜ |
| Model environment dari pustaka CC0 (Kenney/Quaternius) | ⬜ |

### Fase 4 — Vertical Slice ⬜

| Langkah | Status |
|---------|:------:|
| Starter selection (Harimau/Orangutan/Penyu) + cutscene sederhana | ⬜ |
| Gym G2 Api — Pak Lesto (Beruang Muda Lv.14, Ayam Satria Lv.16) | ⬜ |
| Rival + 1 pertarungan rival | ⬜ |
| Pusat pemulihan + toko (Amukan tersedia semua tier) | ⬜ |
| Main end-to-end: mulai → G1 → G2, bisa dimainkan orang lain | ⬜ |
| Export Web (ADR-04) | ⬜ |

### Fase 5 — Produksi konten penuh ⬜

| Langkah | Status |
|---------|:------:|
| 15 spesies line sisanya (builder Blender + data sudah siap semua) | ⬜ |
| 6 pulau lengkap (`docs/world-region.md`) | ⬜ |
| 8 gym + Liga Nusantara + Juara Nara | ⬜ |
| Trio legendary: lokasi, 1 encounter per save | ⬜ |
| Musik/instrumen Nusantara + audio | ⬜ |
| Ekspansi (TCG/mobile) — **terkunci sampai Fase 5 tuntas** (`docs/expansion.md`) | 🧊 |

## 3. Backlog Teknis (hasil audit v0.1, 2026-09-13/14)

Diverifikasi via audit total + eksekusi suite tes pertama (Godot 4.7.2). Item 🧊 sengaja tidak dikerjakan di Fase 1 agar scope prototipe tetap ramping.

| ID | Item | Prioritas | Catatan |
|----|------|-----------|---------|
| B-1 | 4 move status (kikik/fokus/istirahat/benteng_karang) terlihat di UI tapi efek `debuff_atk`/`buff_atk`/`heal_50`/`buff_def` diabaikan engine | 🔨 | ✅ SELESAI `4629f5c` — sistem tahap stat + 4 efek aktif |
| B-2 | PP (`poin`) belum diimplementasikan — move tak pernah habis | 🔨 | ✅ SELESAI `4629f5c` — PP per move + fallback Meronta |
| B-3 | Status **kelumpuhan** unreachable: tak ada move dengan efekData kelumpuhan di `moves.json` (GDD §4.1 mendefinisikannya) | sedang | tambah move Listrik dengan efek kelumpuhan atau revisi GDD |
| C-1 | Kontradiksi clamp stat: `data_loader.gd` min 1 vs `docs/base-stats.md` min 20 | rendah | tidak bermuara pada data saat ini (semua ≥23); samakan salah satu |
| C-2 | Kelumpuhan di-rol 2× per giliran (cek serangan + pesan fase status) | sedang | ✅ SELESAI `4629f5c` — cek lumpuh hanya saat mon mencoba beraksi |
| C-3 | Kabur: peluang flat 60%, abaikan speed | rendah | ✅ SELESAI (Fase 3) — formula Gen-III+ berbasis SPEED (`BattleEngine.coba_kabur`): F = floor(SPE×32/penyebut) + 30×percobaan; docs `gameplay-depth.md` §4.1 |
| C-4 | UI battle memakai posisi absolut tanpa setting `display/window` (stretch) | sedang | layout bisa terpotong pada resolusi lain |
| C-5 | 12 ability dari `gameplay-depth.md` belum ada satu pun di engine | sedang | ✅ SELESAI `3637879` — AbilityEngine, 12/12 aktif di battle |
| C-6 | Latihan (EV-lite) belum diimplementasikan | rendah | ✅ SELESAI `2a6dd71` — cap 50/25, 4:1, Teh Herba, tampil di layar status |
| C-7 | Kosmetik: tangkap berhasil terlog "Battle selesai (menang)" — kurang naratif | rendah | ✅ SELESAI `4629f5c` — kini "(tertangkap)" |
| D-1 | Builder Blender baru 6/15 model MVP (tahap 1 saja) | sedang | 9 model line tahap 2/3 belum ada; terjadwal Fase 1 penutup/Fase 2 |
| E-1 | CI GitHub Actions (validate + tes headless) belum ada | sedang | direncanakan di `tech-stack.md` §5 |
| E-2 | `validate.ps1` hard-code daftar ability & angka konten — perlu edit tiap penambahan konten | rendah | pindahkan whitelist ke data/config |

## 4. Riwayat Keputusan Teknis per Langkah

| Tanggal | Keputusan | Alasan | Ref |
|---------|-----------|--------|-----|
| 2026-09-13 | Kunci ADR-01…07 (Godot 4, 3D low-poly, generator Blender, PC+Web, 15 spesies MVP, JSON data, Git LFS) | proses keputusan terdokumentasi di `docs/tech-stack.md` | `36f78df` |
| 2026-09-13 | Data JSON di root repo (bukan Resource Godot) | single source of truth lintas engine & ekspansi TCG (ADR-06) | `36f78df` |
| 2026-09-13 | Battle engine = static class terpisah dari UI | testable headless; RNG di-inject → tes deterministic | `66968a7` |
| 2026-09-13 | Formula tangkap & damage ikut konvensi Gen-V | teruji, mudah dijelaskan, cocok target keluarga | `f9502c7` |
| 2026-09-14 | Deadlock akhir-giliran-status diperbaiki: cek pingsan pasca-fase status | burn/racun harus bisa mengakhiri battle | `c7fad96` |
| 2026-09-14 | Stat non-HP disinkronkan ke rumus runtime docs (`floor(2×base×lv/100)+5`); kunci `hp` tetap base di dict `stats` | HP runtime tersimpan di `max_hp`; base HP dipakai ulang saat evolusi; damage kini skala level sesuai desain — **mengubah angka damage gameplay** | `4bc8452` |
| 2026-09-14 | Assertion tes "Api vs Daun/Udara" dikoreksi ke 2.0 (2×1) | chart JSON & `type-chart.md` = source of truth; tes salah, bukan data | `4bc8452` |
| 2026-09-14 | Runner tes pakai `Start-Process -PassThru` (bukan `$LASTEXITCODE`) | exit code native exe bisa null di sebagian lingkungan → salah lapor gagal | `4389f5f` |
| 2026-09-14 | Filter `-File` pada pencarian Godot | folder bernama `*.exe` bisa salah terdeteksi sebagai executable | `4389f5f` |
| 2026-09-14 | `ROADMAP.md` dibuat sebagai sumber tunggal status progres; GDD §9 & README menunjuk ke sini | cegah drift antar-dokumen | — |
| 2026-09-14 | Move status buff/debuff/heal **diimplementasikan** (bukan ditunda) via sistem tahap stat ±6, faktor ×1.5/×⅔ | melengkapi 4 move data yang tadinya tak berefek; konsisten kemampuan ability (GDD) yang menyebut "tahap" | `4629f5c` |
| 2026-09-14 | PP diimplementasikan + move darurat **Meronta** (analog Struggle) saat semua PP habis | PP berkurang walau meleset (konvensi Pokémon); UI men-disable tombol PP 0 | `4629f5c` |
| 2026-09-14 | Efek `efekData` hanya diterapkan bila serangan kena (bug: sebelumnya jalan walau meleset) | benar secara aturan battle | `4629f5c` |
| 2026-09-14 | Fase 1 dinyatakan **selesai** — DoD terpenuhi (78 asersi hijau, 3 suite, simulasi battle penuh) | semua kriteria §1 terpenuhi; inspeksi visual editor tetap disarankan saat Fase 2 | `4629f5c` |
| 2026-09-14 | Fase 2 dimulai: inventori & toko Amukan. **Harga baru didefinisikan**: Amukan Rp 200, Kuat Rp 600, Super Rp 900, Nusantara = hadiah event (tidak dijual); uang awal Rp 3.000; stok awal 5 Amukan | `gameplay-depth.md` §3 tidak menetapkan harga → diputuskan di sini + `data/items.json` (source of truth); bonus divalidasi `validate.ps1` agar = konstanta engine | `9fd0a9c` |
| 2026-09-14 | Inventori memakai **static store** (bukan autoload) | bertahan saat scene dimuat ulang tanpa menambah dependensi; testable headless; save/load permanen menyusul | `9fd0a9c` |
| 2026-09-14 | `Tim` memakai **referensi instance yang sama antar battle** (mon aktif = `Tim.aktif()`) | EXP/level/evolusi tidak hilang saat scene dimuat ulang — progresi pemain kini persisten per sesi | `ea7b214` |
| 2026-09-14 | `Tim.tambah()` menolak **anggota ke-7 dan instance duplikat**; tim penuh saat tangkap → wild dilepas (PC-box menyusul) | mencegah state tidak valid; perilaku prototipe dicatat eksplisit | `ea7b214` |
| 2026-09-14 | Mon pingsan otomatis dipulihkan di awal battle (`Tim.pulihkan_semua`) | placeholder pusat pemulihan — kualitas hidup prototipe sampai Fase 3 (pusat pemulihan sungguhan) | `ea7b214` |
| 2026-09-14 | Switch mon = **satu giliran**: lawan menyerang balik sekali (konvensi Pokémon); tombol mon aktif/pingsan nonaktif | sesuai GDD §4.1 (pilihan giliran Serang/Ganti/Item/Kabur) | `40c3987` |
| 2026-09-14 | Field `deskripsi` 30 spesies diisi ke `nusamons.json` via script one-off Godot (**intify**: angka bulat dikembalikan ke int — JSON Godot mem-parse semua angka sebagai float) | `docs/nusadex.md` menargetkan field ini tapi belum terisi; teks UTF-8 bersih; `validate.ps1` kini wajibkan deskripsi terisi | `40c3987` |
| 2026-09-14 | UI Nusadex = **overlay** di battle scene (bukan scene terpisah) — konsisten pola menu toko; `habitatPulau` ternyata **array pulau** → ditampilkan sebagai daftar dipisah koma | prototipe single-scene; dokumentasi nusadex.md §3.2 (daftar + detail) terpenuhi | `40c3987` |
| 2026-09-14 | 12 ability diimplementasikan sebagai **kelas `AbilityEngine`** terpisah (hook: kalkulasi damage, akurasi, masuk battle, sentuhan fisik, akhir giliran, blokir kabur/ganti) + status baru **`terpikat`** (Madu Manis; 50% gagal menyerang) | engine tetap tipis; unit test statistical (fixed seed) memastikan peluang 10%/30%/50% sesuai docs | `3637879` |
| 2026-09-14 | Cengkeraman Kuat memblokir kabur/ganti **tanpa mengonsumsi giliran** (log penjelasan) | opsi kembali tersedia — pemain tidak kehilangan giliran karena aksi tak tersedia | `3637879` |
| 2026-09-14 | Fix bug saat implementasi: ejaan ability **`napas_dalam`** (bukan napas_dalan) — cocokkan ke data & docs; fix tes flaky: asersi tangkap dibuat relatif (lemparan bagian-3 bisa saja menangkap acak) | single source of truth = data; tes harus deterministik meski alur acak | `3637879` |
| 2026-09-14 | Latihan (EV-lite): poin diberikan ke **stat kategori move terakhir pemain** (fisik→atk, spesial→spa); bonus via `stats_efektif` (stats dasar tetap — bersih untuk save/diagnosa) | sesuai gameplay-depth §6; 4:1, cap 50/25; Teh Herba Rp 500 reset | `2a6dd71` |
| 2026-09-14 | Save/load = **JSON v1 di `user://simpanan.json`** (bukan Resource/custom biner): uang, stok, tim (level/HP/status/exp/latihan), nusadex; auto-load saat mulai & auto-save tiap battle selesai | JSON = ADR-06; user:// aman untuk PC & Web; validasi versi untuk migrasi kelak | `2a6dd71` |
| 2026-09-14 | Pratinjau model 3D = **SubViewport + fallback diam** bila `.glb` belum ada (`ResourceLoader.exists`) | runtime siap untuk 15 model tahap 2/3; aset .glb menunggu eksekusi Blender (D-1) — tidak memblokir Fase 2 | `2a6dd71` |
| 2026-09-14 | Klarifikasi risiko IP di dokumentasi (GDD §10 + `world-region.md` §8 baru): klaim "risiko IP" **hanya** menyasar similarity dengan Pokémon — nama lokasi/kota nyata bukan risiko IP; peta fiksi dipilih karena alasan kreatif (pacing/gating, kebebasan akurasi) & teknis (lisensi data peta: ToS Google Maps / ODbL OSM, performa Web), bukan mitigasi hukum | justifikasi dokumentasi dibuat akurat & tahan uji bila dipakai justifikasi ke pihak eksternal; mencegah salah kutip ulang | — |
| 2026-09-14 | Fase 3 dimulai — peta Jawa: koneksi **eksplisit dua arah** (8 jalur untuk 5 lokasi), gate **hanya di arah masuk** (jalan pulang bebas — konvensi genre); gate data-driven di `world.json` (`{"jenis":"lencana","id":1}` pada kota_harapan→rute_2), jenis gate tak dikenal = gagal aman (terkunci) | traversal bisa dites headless; gate tanpa logika hard-code; konsisten ADR-06 | — |
| 2026-09-14 | Progres dunia = **static store** `Progres` (lokasi + lencana) — bukan autoload; `WorldEngine.pindah()` murni (tak memutasi state, pemanggil yang update) | konvensi Inventori/Nusadex; engine murni mudah dites; save permanen menyusul di langkah lencana (simpanan v2) | — |
| 2026-09-14 | Tabel encounter rute (spesies/bobot/level) sudah ada di `data/world.json` — engine rol-nya di langkah 2 | data & sistem terpisah; validate.ps1 sudah menjaga konsistensi id spesies | — |
| 2026-09-14 | Encounter = **hybrid**: tabel khas per rute (world-region §2.1) untuk MVP + pool turunan **habitatPulau × bobot rarity** (gameplay-depth §4: 60/25/12/3/0/0) untuk lokasi tanpa tabel (Fase 4/5); starter & legendary bobot 0 (tidak liar) | menghormati desain per-rute sekaligus janji data habitat; gagal aman untuk rarity tak dikenal | — |
| 2026-09-14 | Handoff world → battle via **antrean static** (`EncounterSystem.antrean_liar`, dikonsumsi sekali); battle tanpa antrean tetap rol acak prototipe (WILD_IDS) | konsisten pola static store; test_scene tak terpengaruh (proses terpisah) | — |
| 2026-09-14 | C-3 ditutup: kabur liar = formula Gen-III+ (`coba_kabur`), +30 per percobaan gagal, reset tiap battle; SPE = stats_efektif × faktor tahap (konsisten urutan giliran); Cengkeraman Kuat tetap blokir | kabur baru benar-benar terpakai sejak ada encounter dunia; didokumentasikan `gameplay-depth.md` §4.1 | — |
| 2026-09-14 | Trainer/gym = **data-driven** `data/trainers.json` (tim {spesies,level} berurutan = orde dikirim; dialog intro/menang/kalah; hadiah_uang; lencana {id,nama}); `TrainerEngine.buat_tim()` menghasilkan NusamonInstance stage 0; `trainer_di_kota()` menghubungkan gym ke lokasi via `gym.kota` | ADR-06 (data JSON = source of truth); gym tanpa trainer (mis. Arunika) otomatis "terkunci" — tidak perlu flag manual | — |
| 2026-09-14 | Hadiah gym G1 = **Rp 1.200 + Lencana Harapan**; nama lencana diambil dari nama kota (Kota Harapan); harga tidak ditetapkan docs → diputuskan di sini (pola sama dengan harga Amukan di Fase 2) | single source of truth = data + catatan keputusan | — |
| 2026-09-14 | POI gym di world scene: bila kota punya trainer, POI `gym_*` digantikan panel khusus (leader/profesi/tim/hadiah + tombol TANTANG, dinonaktifkan sampai langkah 4) | hindari duplikasi UI; integritas data tetap satu sumber | — |

## 5. Referensi

- Rencana makro: `docs/GDD.md` §9 · ADR: `docs/tech-stack.md` · MVP scope: `docs/GDD.md` §8
- Data: `data/*.json` (+ `tools/validate.ps1`) · Tes: `game/tests/` (+ `tools/run_tests.ps1`)
- Generator aset: `tools/blender/` · Panduan menambah spesies: `tools/blender/README.md`
