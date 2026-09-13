# NUSAMON 🇮🇩

**Nusantara Monsters** — Game RPG monster-collection bergaya Pokémon dengan latar fauna dan budaya Indonesia.

> *"Dari Alam Nusantara, Lahir Para Monster."*

## Status Proyek

> **Detail step-by-step per fase: lihat `ROADMAP.md`** (sumber tunggal status progres).

| Fase | Status |
|------|--------|
| Perencanaan & Desain (GDD) | ✅ Selesai v0.1 |
| Keputusan Teknis | ✅ Godot 4 + 3D low-poly (`docs/tech-stack.md`) |
| Tooling Generator Aset | 🔨 Selesai (6/15 model MVP; perlu Blender untuk eksekusi) |
| Fase 1 — Prototipe Battle | ✅ **Selesai** — battle core + tangkap + EXP/evolusi + PP + tahap stat (buff/debuff/heal) + UI; **78 asersi hijau (3 suite, Godot 4.7.2)**. Detail: `ROADMAP.md` |
| Prototipe World/Catch (Fase 2) | 🔨 **Berjalan** — inventori & toko Amukan + tim/partai (maks. 6, tangkap masuk tim, EXP persisten) + switch mon + Nusadex + **12 ability aktif** selesai; berikutnya: Latihan EV-lite, save/load, impor model tahap 2/3 |

## Struktur Proyek

Root repo = root proyek Godot (`res://` = path repo) — data JSON terbaca langsung tanpa duplikasi.

```
NUSAMON/
├── README.md              # Dokumen ini
├── ROADMAP.md             # Status progres granular step-by-step (sumber tunggal status)
├── project.godot          # Proyek Godot 4 (root)
├── docs/                  # Game Design Document
│   ├── GDD.md             # GDD utama (visi, sistem, roadmap)
│   ├── roster.md          # Roster 30 spesies Nusamons (v2)
│   ├── type-chart.md      # Matriks tipe 11x11
│   ├── base-stats.md      # Base stats & aturan skala evolusi
│   ├── world-region.md    # Desain dunia: pulau, kota, gym, legendary
│   ├── gameplay-depth.md  # Ability, item tangkap, kurva EXP, Latihan
│   ├── nusadex.md         # Desain Nusadex + deskripsi 30 entri
│   ├── expansion.md       # Roadmap franchise: TCG, mobile, spin-off
│   └── tech-stack.md      # Keputusan teknis (ADR)
├── data/                  # Data siap pakai untuk engine
│   ├── type-chart.json    # Data efektivitas tipe (machine-readable)
│   ├── nusamons.json      # Data 30 spesies + tahapan evolusi
│   └── moves.json         # Data move/skill pertarungan
├── game/                  # Kode GDScript (data loader, battle, dst.)
├── assets/models/         # Model .glb hasil generator
└── tools/
    ├── blender/           # Generator aset 3D low-poly (Python Blender)
    └── validate.ps1       # Validasi data JSON
```

## Keputusan Desain Kunci (Locked)

1. **30 spesies Nusamons** berbasis fauna asli Indonesia (+1 flora: Kantong Semar)
2. **11 tipe elemen**: Api, Air, Daun, Tanah, Udara, Normal, Listrik, Racun, Petarung, Naga, Baja
3. **Tanpa tema mistis/horor** — ceria, keluarga-friendly, semua umur
4. **3 Legendary single-stage** (tidak berevolusi): Elang Garuda, Cenderawasih Agung, Paus Samudra
5. **3 Pseudo-Legendary 3-tahap**: line Komodo, Gajah, Badak
6. **Maksimal 3 tahap evolusi** per spesies
7. **Starter trio**: Harimau (Api), Orangutan (Daun), Penyu (Air)
8. **Engine & art**: Godot 4 + 3D low-poly; aset dibuat terprogram via script Blender; MVP **PC + Web**, **15 spesies**; repo public

## Dokumentasi

- Baca `docs/GDD.md` terlebih dahulu untuk gambaran utuh.
- Data teknis di folder `data/` dalam format JSON agar engine-agnostic (Godot/Unity/custom).
