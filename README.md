# NUSAMON 🇮🇩

**Nusantara Monsters** — Game RPG monster-collection bergaya Pokémon dengan latar fauna dan budaya Indonesia.

> *"Dari Alam Nusantara, Lahir Para Monster."*

## Status Proyek

| Fase | Status |
|------|--------|
| Perencanaan & Desain (GDD) | ✅ Selesai v0.1 |
| Pemilihan Engine | ⏳ Menunggu keputusan |
| Prototipe Battle System | ⬜ Belum mulai |
| Prototipe World/Catch | ⬜ Belum mulai |

## Struktur Proyek

```
NUSAMON/
├── README.md              # Dokumen ini
├── docs/                  # Game Design Document
│   ├── GDD.md             # GDD utama (visi, sistem, roadmap)
│   ├── roster.md          # Roster 30 spesies Nusamons (v2)
│   ├── type-chart.md      # Matriks tipe 11x11
│   ├── base-stats.md      # Base stats & aturan skala evolusi
│   ├── world-region.md    # Desain dunia: pulau, kota, gym, legendary
│   ├── gameplay-depth.md  # Ability, item tangkap, kurva EXP, Latihan
│   ├── nusadex.md         # Desain Nusadex + deskripsi 30 entri
│   └── expansion.md       # Roadmap franchise: TCG, mobile, spin-off
└── data/                  # Data siap pakai untuk engine
    ├── type-chart.json    # Data efektivitas tipe (machine-readable)
    ├── nusamons.json      # Data 30 spesies + tahapan evolusi
    └── moves.json         # Data move/skill pertarungan
```

## Keputusan Desain Kunci (Locked)

1. **30 spesies Nusamons** berbasis fauna asli Indonesia (+1 flora: Kantong Semar)
2. **11 tipe elemen**: Api, Air, Daun, Tanah, Udara, Normal, Listrik, Racun, Petarung, Naga, Baja
3. **Tanpa tema mistis/horor** — ceria, keluarga-friendly, semua umur
4. **3 Legendary single-stage** (tidak berevolusi): Elang Garuda, Cenderawasih Agung, Paus Samudra
5. **3 Pseudo-Legendary 3-tahap**: line Komodo, Gajah, Badak
6. **Maksimal 3 tahap evolusi** per spesies
7. **Starter trio**: Harimau (Api), Orangutan (Daun), Penyu (Air)

## Dokumentasi

- Baca `docs/GDD.md` terlebih dahulu untuk gambaran utuh.
- Data teknis di folder `data/` dalam format JSON agar engine-agnostic (Godot/Unity/custom).
