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
| 1 — Prototipe Battle | 🔨 **±85%** | Battle 1v1, tangkap, EXP/evolusi, UI scene, tes headless | Battle end-to-end (serang/tangkap/kabur) + EXP + evolusi + suite tes hijau + UI terverifikasi di editor |
| 2 — Catch & Nusadex | ⬜ Belum mulai | Inventori, tim/partai, Nusadex, ability engine | Tangkap masuk tim, Nusadex terisi, ability & PP aktif |
| 3 — World & Gym pertama | ⬜ Belum mulai | World map Jawa, G1 Normal (Bu Sari) | Battle trainer + lencana G1 |
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

### Fase 1 — Prototipe Battle 🔨

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
| Fix kelumpuhan di-rol dua kali per giliran | 🧊 | backlog §3 |

**Kualitas & tooling**

| Langkah | Status | Referensi |
|---------|:------:|-----------|
| Tes headless `test_battle.gd` (29 asersi) | ✅ | `66968a7`, diperbaiki `4bc8452` |
| Tes headless `test_catch_exp.gd` (23 asersi) | ✅ | `f9502c7`, asersi diperbaiki `4bc8452` |
| Runner `tools/run_tests.ps1` menjalankan kedua suite + exit code andal | ✅ | `4389f5f` |
| Upgrade proyek ke Godot 4.7 + verifikasi runtime | ✅ | `4389f5f` — 52 asersi hijau (0 gagal) |
| Verifikasi parse JSON (file dengan BOM) di Godot 4.7.2 | ✅ | `4389f5f` — ketiga JSON terbaca normal |
| Sinkronisasi stat runtime kode ↔ `docs/base-stats.md` | ✅ | `4bc8452` |

**Sisa untuk menutup Fase 1** (DoD):

| Langkah | Status | Catatan |
|---------|:------:|---------|
| Verifikasi UI battle di editor/launch (bukan hanya headless) | ⬜ | jalankan `godot --path .` lalu main 1 sesi battle penuh |
| Keputusan move status buff/debuff/heal (kikik/fokus/istirahat/benteng_karang): implement minimal atau resmi tunda ke Fase 2 | ⬜ | saat ini efeknya diabaikan engine — lihat backlog B-1 |
| Sistem PP (`poin`): implement atau catat eksplisit sebagai tunda | ⬜ | lihat backlog B-2 |

### Fase 2 — Catch & Nusadex ⬜ (rencana granular)

| Langkah | Status |
|---------|:------:|
| Inventori Amukan terbatas (beli/toko, pengurangan stok) | ⬜ |
| Tim/partai (maks. 6) + hasil tangkap masuk tim | ⬜ |
| Switch/tukar Nusamon saat battle (GDD §4.1) | ⬜ |
| Nusadex: record lihat/tangkap, layar daftar + detail (`docs/nusadex.md`) | ⬜ |
| Ability engine: 12 ability dari `docs/gameplay-depth.md` | ⬜ |
| Move status buff/debuff/heal + stat stage (naik/turun tahap) | ⬜ |
| Sistem PP move (`poin` di `moves.json`) | ⬜ |
| Latihan (EV-lite): poin per battle, cap 50/25, konversi 4:1, item reset | ⬜ |
| Penyimpanan (save/load) — format TBD | ⬜ |
| Impor model tahap 2/3 + tampil di battle | ⬜ |

### Fase 3 — World & Gym pertama ⬜

| Langkah | Status |
|---------|:------:|
| World map Jawa ringkas (GDD §8): Desa Sumberrejo → Rute 1 → Kota Harapan → Rute 2 → Kota Arunika | ⬜ |
| Sistem encounter liar per rute (`habitatPulau` + bobot rarity) | ⬜ |
| Gym G1 Normal — Bu Sari (Monyet Kecil Lv.8, Ayam Jantan Lv.10) | ⬜ |
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
| B-1 | 4 move status (kikik/fokus/istirahat/benteng_karang) terlihat di UI tapi efek `debuff_atk`/`buff_atk`/`heal_50`/`buff_def` diabaikan engine | 🔨 | butuh sistem stat stage; dijadwalkan Fase 1 penutup atau Fase 2 |
| B-2 | PP (`poin`) belum diimplementasikan — move tak pernah habis | 🔨 | gabung dengan B-1 |
| B-3 | Status **kelumpuhan** unreachable: tak ada move dengan efekData kelumpuhan di `moves.json` (GDD §4.1 mendefinisikannya) | sedang | tambah move Listrik dengan efek kelumpuhan atau revisi GDD |
| C-1 | Kontradiksi clamp stat: `data_loader.gd` min 1 vs `docs/base-stats.md` min 20 | rendah | tidak bermuara pada data saat ini (semua ≥23); samakan salah satu |
| C-2 | Kelumpuhan di-rol 2× per giliran (cek serangan + pesan fase status) | sedang | roll kedua hanya menghasilkan log palsu |
| C-3 | Kabur: peluang flat 60%, abaikan speed | rendah | desain formula speed-based untuk Fase 3 |
| C-4 | UI battle memakai posisi absolut tanpa setting `display/window` (stretch) | sedang | layout bisa terpotong pada resolusi lain |
| C-5 | 12 ability dari `gameplay-depth.md` belum ada satu pun di engine | sedang | terjadwal Fase 2 |
| C-6 | Latihan (EV-lite) belum diimplementasikan | rendah | terjadwal Fase 2 |
| C-7 | Kosmetik: tangkap berhasil terlog "Battle selesai (menang)" — kurang naratif | rendah | |
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

## 5. Referensi

- Rencana makro: `docs/GDD.md` §9 · ADR: `docs/tech-stack.md` · MVP scope: `docs/GDD.md` §8
- Data: `data/*.json` (+ `tools/validate.ps1`) · Tes: `game/tests/` (+ `tools/run_tests.ps1`)
- Generator aset: `tools/blender/` · Panduan menambah spesies: `tools/blender/README.md`
