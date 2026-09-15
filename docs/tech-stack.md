# Tech Stack & Keputusan Teknis (ADR) — v0.1

> Architecture Decision Records NUSAMON. Setiap keputusan besar dicatat di sini beserta alternatifnya dan alasannya.

## 1. Keputusan Terkunci

| # | Keputusan | Pilihan | Alternatif yang Ditolak | Alasan |
|--:|-----------|---------|-------------------------|--------|
| ADR-01 | Engine | **Godot 4 (GDScript)** | Unity, GameMaker, Web-only | Lisensi MIT gratis; export PC+Web+Android dari satu proyek; JSON terbaca langsung; arsitektur node cocok untuk RPG grid |
| ADR-02 | Art direction | **3D low-poly stylized** | Pixel art (ditolak pemilik — kualitas visual kurang), HD-2D (terlalu berat untuk tim kecil) | Kualitas visual modern; satu aset 3D melayani game, artwork TCG, dan Nusadex |
| ADR-03 | Pipeline aset | **Generator terprogram** — script Python Blender headless → glTF | Modeling manual per monster | Murah & konsisten untuk ±70 tahap evolusi; deterministik; bisa di-batch & dipoles bertahap |
| ADR-04 | Platform MVP | **PC + Web (HTML5)** | Android langsung (ditunda), konsol (jauh) | UI touch & performa mobile menambah kompleksitas; Web = distribusi termudah |
| ADR-05 | Scope art MVP | **15 spesies** (3 starter line + Monyet + Ayam + Rusa) | 30 spesies langsung | Pipeline 3D terbukti dulu di skala kecil; sisanya masuk fase produksi |
| ADR-06 | Data | JSON di `data/` (root repo) | Resource Godot, database | Single source of truth lintas engine & ekspansi (TCG); sudah tervalidasi |
| ADR-07 | Versi kontrol | Git + GitHub; **LFS untuk aset biner** | Tanpa LFS | Model .glb & tekstur membesar seiring produksi; LFS menjaga repo sehat |

## 2. Struktur Proyek

Root repo = root proyek Godot, sehingga `res://` = path repo (data JSON langsung terbaca tanpa duplikasi):

```
project.godot            # Proyek Godot 4 (root)
data/                    # Data JSON — satu-satunya sumber data (nusamons, moves, type-chart, items, world, trainers, audio)
game/                    # Kode GDScript (loader, battle, dst.)
assets/models/           # Output generator (*.glb, LFS)
assets/audio/            # Audio (.wav placeholder terprogram; .ogg CC0 nanti)
tools/blender/           # Generator aset low-poly (headless)
tools/audio/             # Generator placeholder audio (Python stdlib)
tools/validate.ps1       # Validasi data JSON`ntools/run_tests.ps1      # Runner tes headless (18 suite)`ntools/export_web.ps1     # Export build Web
docs/                    # 9 dokumen desain
```

## 3. Pipeline Aset 3D

```
tools/blender/nusamon_build.py      (framework + builder per spesies)
   ↓  blender --background --python tools/blender/nusamon_build.py -- \
        --species anak_rimau,orangkici --out assets/models
assets/models/<id>.glb              (low-poly, material warna flat)
   ↓  Godot mengimpor glTF otomatis
game/                               (scene battle & world memakai model)
```

**Aturan pipeline (wajib bagi semua generator):**
1. Nama file = ID tahapan snake_case (`anak_rimau.glb`, `monyet_kecil.glb`).
2. Model berpusat di origin, berdiri di lantai z=0, menghadap arah -Y (depan kamera battle).
3. Material = warna flat (Principled BSDF, roughness tinggi) — tanpa tekstur di MVP.
4. Satu root Empty sebagai parent seluruh part — memudahkan animasi kelak.
5. Script deterministik: hasil identik setiap dijalankan (idempotent).
6. Hanya pakai API Blender stabil: `primitive_*_add`, `export_scene.gltf`.

## 4. MVP — 15 Model Spesies

| Line | Model (ID file) |
|------|-----------------|
| Rimau | `anak_rimau`, `rimau_muda`, `rimau_agung` |
| Orangutan | `orangkici`, `oranguda`, `orangraja` |
| Penyu | `penyuci`, `penyula`, `samudragon` |
| Monyet | `monyet_kecil`, `monyet_emas` |
| Ayam | `ayam_jantan`, `ayam_satria` |
| Rusa | `rusa_muda`, `rusa_raksasa` |

*Fase 5 selesai: 62/62 model (semua tahapan 30 line roster v2) digenerate via Blender 5.2 headless — D-1 tutup.*

## 5. Kontrol Versi & CI

- LFS: `*.glb`, `*.blend`, `*.png`, `*.ogg` (lihat `.gitattributes`). Placeholder `.wav` audio (~1,9 MB total) sengaja disimpan normal; `.ogg` final akan masuk LFS.
- `tools/validate.ps1` wajib lolos sebelum data masuk `main` (nanti diotomasi via GitHub Actions).

## 6. Risiko Teknis & Mitigasi

| Risiko | Mitigasi |
|--------|----------|
| API Blender berubah antar versi | Generator hanya memakai API stabil (primitif + export glTF); versi Blender dicatat di `tools/blender/README.md` |
| Kualitas model terprogram terbatas | Gaya low-poly memang sederhana; dievaluasi visual sejak MVP; model tertentu bisa dipoles manual nanti |
| Ukuran Web export membengkak | Low-poly + tanpa tekstur = aset kecil |
| Git LFS belum terpasang | Semua tool tetap jalan tanpa LFS; LFS diaktifkan saat aset biner mulai masuk |
