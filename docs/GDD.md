# NUSAMON — Game Design Document (v0.1)

> Dokumen ini mengunci seluruh keputusan desain hasil diskusi. Setiap perubahan desain harus memperbarui dokumen ini.

---

## 1. Ringkasan

**NUSAMON (Nusantara Monsters)** adalah game RPG monster-collection bergaya Pokémon klasik (turn-based, catch & collect, gyms) dengan seluruh konten berakar pada **fauna alam Indonesia**. Target nuansa: ceria, petualangan, keluarga-friendly.

**Tagline:** *"Dari Alam Nusantara, Lahir Para Monster."*

| Aspek | Keputusan |
|-------|-----------|
| Genre | Monster-collection RPG, turn-based battle |
| Perspektif | Top-down (2D atau 3D low-poly — TBD) |
| Platform | TBD (kandidat: PC, Android, Web) |
| Engine | TBD (kandidat: Godot 4 — direkomendasikan) |
| Target audiens | Semua umur (E10+ setara), penggemar Pokémon |
| Bahasa | Indonesia (utama), Inggris (opsional kemudian) |

## 2. Design Pillars

1. **Nusantara Autentik** — 100% fauna/flora Indonesia; tidak ada Pokémon resmi, tidak ada horor/mistis.
2. **Klasik tapi Dipoles** — formula battle Pokémon yang teruji, dengan QoL modern (dokumentasi tipe in-game, petunjuk jelas).
3. **Koleksi yang Memuaskan** — tiap spesies punya identitas visual & nama unik per tahap evolusi.
4. **Mudah Dipelajari, Berkedalaman** — casual bisa tamat, kompetitif bisa mengejar base stats & meta.

## 3. Core Gameplay Loop

```
Jelajah Dunia → Encounter liar → TANGKAP (Lempar Amukan) / LAWAN
     ↑                                        ↓
Gym/Story Progress ← Naikkan Tim (EXP, Evolusi, Move) ←
```

Loop mikro: setiap battle memberi EXP → level up → move baru/evolusi (reward berkala).
Loop makro: kumpulkan 30 spesies (Nusadex) → kalahkan 8 Gym → Elite Empat → Juara Nusantara.

## 4. Sistem Utama

### 4.1 Sistem Battle (Turn-based)
- 1v1 (satu Nusamon aktif per sisi), tim maksimal 6.
- Pilihan tiap giliran: **Serang / Ganti / Item / Kabur**.
- Urutan giliran berdasar stat **SPE** (Speed); move prioritas dapat mengubahnya (field **`prioritas`** di `data/moves.json`, default 0).
- Damage formula (basis Gen-V Pokémon):

```
Damage = floor(floor(floor(2*Level/5 + 2) * Power * ATK/DEF) / 50) + 2
         lalu dikalikan: modifier tipe × stab × random(0.85–1.00) × faktor lain
```

- STAB (Same Type Attack Bonus) = ×1.5 jika tipe move = tipe pengguna.
- Status: **Luka Bakar** (Api), **Racun** (Racun), **Kelumpuhan** (Listrik), **Tidur** (Daun — serebuk), dst.
- Data efek status move tersedia terstruktur di field **`efekData`** (`jenis` + `peluang`) pada `data/moves.json`.

### 4.2 Sistem Tipe (11 Tipe)
`Api, Air, Daun, Tanah, Udara, Normal, Listrik, Racun, Petarung, Naga, Baja`
→ Matriks lengkap: `docs/type-chart.md` / `data/type-chart.json`.
**Kewajiban QoL:** chart tipe & indikator efektivitas harus terlihat in-game.

### 4.3 Sistem Tangkap
- Item: **Amukan** (Poke Ball versi NUSAMON) — lempar ke target yang sudah dilemahkan.
- Formula tangkap (basis Gen-V):

```
a = ((3*MaxHP - 2*CurHP) * CatchRate * BallBonus) / (3*MaxHP)
catch jika random(0..255) < a (dengan shake check)
```

- Encounter rate per spesies menurut rarity (Common > Uncommon > Rare > Legendary).

### 4.4 Progresi Statistik
- 6 stat: **HP, ATK, DEF, SPA, SPD, SPE**.
- **Level 1–100**, EXP kurva medium-fast.
- Base stats per spesies: `docs/base-stats.md`.
- **Disederhanakan dari Pokémon:** tidak ada IV; ada **Latihan (EV-lite)** — bonus stat dari battle, capped, bisa di-reset (transparan untuk pemain). *Bisa dinaikkan kompleksitasnya nanti.*

### 4.5 Evolusi
- Maksimal 3 tahap; pemicu utama: **level tertentu** (nanti bisa ditambah item/lokasi).
- Skala stat per tahap: lihat `docs/base-stats.md` (60%/80%/100% untuk line 3-tahap).
- Tipe dapat berubah saat evolusi (contoh: Arwana → Arwana Naga mendapat tipe Naga).

### 4.6 Struktur Progresi Dunia
- **8 Gym** bertema kota/pulau & tipe → lencana → **Elite Empat** → **Juara Nusantara**.
- Legendary (3) ditemukan di lokasi tersembunyi, hanya 1 per save, tidak bisa berevolusi.

## 5. Dunia & Nusadex

- **Region Nusantara**: satu region game = **6 pulau sub-region + Laut Nusantara** (laut transisi):
  **Jawa** (pemula) → **Sumatra** → **Kalimantan** → **Sulawesi** → **Bali & Nusa Tenggara** → **Maluku & Papua**.
- Skala: 1 pulau = 2-3 kota + 2-3 rute + 1 landmark (total ±18 lokasi); batas laut = gating progresi (perahu/lencana).
- **Nusadex** = Pokédex: 30 entri spesies, mencatat tahapan evolusi, tipe, habitat pulau, dan deskripsi fauna aslinya (edukatif!).
- Gym leader & tokoh diambil dari profesi/budaya positif Indonesia (pencak silat, nelayan, petani, pandai besi) — **tanpa okultisme**.
- Detail lengkap (kota, rute, 8 gym, Elite Empat, lokasi legendary, gate flow): `docs/world-region.md`.


## 6. Roster

30 spesies final — detail lengkap di `docs/roster.md` dan `data/nusamons.json`:

- **Starter (3):** Rimau (Api), Orangutan (Daun), Penyu (Air) — masing-masing 3 tahap.
- **Legendary (3, single-stage):** Elang Garuda, Cenderawasih Agung, Paus Samudra.
- **Pseudo-Legendary (3, 3 tahap):** Komodo (→Naga), Gajah, Badak (→Baja).
- **Rare (10), Uncommon (2), Common (9)** — mayoritas 2 tahap.

## 7. Art & Audio

- **Art (terkunci — ADR-02):** **3D low-poly stylized**. Model monster dibuat **terprogram** via script Python Blender headless (`tools/blender`) → export glTF → Godot (lihat `docs/tech-stack.md`).
- **Palet warna tropis** Indonesia (hijau rimba, biru samudra, oranye senja).
- **Environment:** disusun dari pustaka aset CC0 (Kenney/Quaternius) di fase awal; monster dibuat custom via generator.
- **Musik:** nuansa instrumen Nusantara (gamelan, angklung, kolintang) yang diaransemen modern.
- **UI:** ikon tipe berwarna, font yang mendukung bahasa Indonesia.

## 8. Scope MVP (Prototipe Pertama)

| Item | Isi |
|------|-----|
| Wilayah | Jawa ringkas: Desa Sumberrejo → Rute 1 → Kota Harapan (G1) → Rute 2 → Kota Arunika (G2) |
| Spesies | **15 spesies**: 3 starter line (9 model) + Monyet (2) + Ayam (2) + Rusa (2) |
| Platform | **PC + Web** (ADR-04; Android menyusul) |
| Sistem | Battle, tangkap, Nusadex, EXP/level, evolusi |
| Konten | 2 gym leader (Bu Sari–Normal, Pak Lesto–Api) + 1 rival + cutscene sederhana |
| Aset | Model low-poly dibuat via `tools/blender` (ADR-03) |

## 9. Roadmap

1. **Fase 0 — Desain** ✅ (GDD, roster, type chart, stats)
2. **Fase 1 — Prototipe Battle** (engine disipasi, pertarungan 1v1 berjalan)
3. **Fase 2 — Catch & Nusadex**
4. **Fase 3 — World & Gym pertama**
5. **Fase 4 — Vertical Slice** (MVP lengkap, bisa dimainkan end-to-end)
6. **Fase 5 — Produksi konten penuh** (30 spesies, semua pulau, story)

## 10. Risiko & Catatan

- **IP:** semua konten original berbasis fauna — aman dari klaim. Hindari nama/visual yang terlalu mirip Pokémon.
- **Scope creep:** disiplin pada MVP; 30 spesies itu sudah ramping dibanding Pokémon (100+).
- **Art asset:** model dibuat terprogram via script Blender (konsisten & murah di ±70 tahap evolusi); gaya dievaluasi sejak MVP.

---
*Versi 0.1 — disusun dari diskusi desain. Data teknis terkait: `data/*.json`.*
