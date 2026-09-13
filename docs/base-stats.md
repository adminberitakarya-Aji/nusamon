# Base Stats NUSAMON

> 6 stat: **HP, ATK, DEF, SPA, SPD, SPE** (format Pokémon: SPA = Special Attack, SPD = Special Defense, SPE = Speed).
> Nilai di bawah = base stats **tahap akhir** tiap spesies.

## Aturan Skala per Tahap Evolusi

| Jumlah Tahap | Tahap 1 (dasar) | Tahap 2 (tengah) | Tahap 3 (final) |
|--------------|----------------:|-----------------:|----------------:|
| 3 tahap | ×0.60 | ×0.80 | ×1.00 |
| 2 tahap | ×0.65 | ×1.00 | — |
| 1 tahap (single) | ×1.00 | — | — |

- Rumus: `stat_tahap = round(baseStatsFinal × skala)` — dibulatkan ke atas, nilai minimum tiap stat = 20.
- Level evolusi standar: 3-tahap = Lv.16 & Lv.36; 2-tahap = Lv.22. (Dapat ditinjau per spesies.)
- Tipe dapat berubah saat evolusi (lihat `data/nusamons.json`).

## Tabel Base Stats (Tahap Final)

| # | Nusamon | Tipe | HP | ATK | DEF | SPA | SPD | SPE | Total |
|--:|---------|------|---:|----:|----:|----:|----:|----:|------:|
| 1 | Rimau Agung | Api | 80 | 120 | 75 | 65 | 70 | 110 | 520 |
| 2 | Orangraja | Daun | 100 | 85 | 105 | 80 | 95 | 45 | 510 |
| 3 | Samudragon | Air | 95 | 70 | 120 | 75 | 110 | 50 | 520 |
| 4 | Elang Garuda | Udara/Petarung | 90 | 115 | 85 | 75 | 80 | 145 | 590 |
| 5 | Cenderawasih Agung | Udara/Api | 85 | 70 | 80 | 125 | 115 | 120 | 595 |
| 6 | Paus Samudra | Air | 145 | 85 | 105 | 95 | 105 | 60 | 595 |
| 7 | Komodo Raja | Tanah/Naga | 100 | 135 | 110 | 60 | 75 | 95 | 575 |
| 8 | Gajah Raksasa | Tanah | 125 | 115 | 120 | 60 | 80 | 55 | 555 |
| 9 | Badak Baja | Tanah/Baja | 110 | 130 | 140 | 50 | 75 | 45 | 550 |
| 10 | Hiu Raksasa | Air | 75 | 110 | 65 | 45 | 55 | 95 | 445 |
| 11 | Buaya Raksasa | Air/Tanah | 85 | 105 | 80 | 45 | 60 | 55 | 430 |
| 12 | Banteng Murba | Tanah/Petarung | 80 | 115 | 75 | 35 | 55 | 65 | 425 |
| 13 | Babirusa Raksasa | Tanah | 90 | 85 | 100 | 40 | 60 | 60 | 435 |
| 14 | Beruang Madu | Normal/Api | 100 | 85 | 85 | 70 | 70 | 45 | 455 |
| 15 | Rangkong Agung | Udara | 80 | 70 | 70 | 85 | 80 | 70 | 455 |
| 16 | Merak Agung | Udara | 75 | 55 | 70 | 100 | 95 | 75 | 470 |
| 17 | Lumba Petir | Air/Listrik | 70 | 70 | 55 | 90 | 70 | 105 | 460 |
| 18 | Arwana Naga | Air/Naga | 80 | 105 | 70 | 65 | 65 | 75 | 460 |
| 19 | Gurita Raksasa | Air/Petarung | 85 | 80 | 70 | 100 | 75 | 60 | 470 |
| 20 | Kakatua Raja | Udara/Normal | 70 | 55 | 60 | 85 | 85 | 75 | 430 |
| 21 | Ular Raksasa | Racun | 70 | 95 | 65 | 55 | 55 | 80 | 420 |
| 22 | Rusa Raksasa | Normal | 60 | 70 | 55 | 45 | 50 | 90 | 370 |
| 23 | Monyet Emas | Normal | 60 | 75 | 50 | 50 | 50 | 100 | 385 |
| 24 | Ayam Satria | Normal/Api | 60 | 90 | 55 | 50 | 50 | 80 | 385 |
| 25 | Kupu-kupu Ekor Walet | Udara/Daun | 55 | 45 | 50 | 85 | 85 | 80 | 400 |
| 26 | Udang Raksasa | Air | 55 | 90 | 60 | 35 | 40 | 80 | 360 |
| 27 | Kepiting Kenari | Air/Tanah | 70 | 80 | 105 | 35 | 45 | 40 | 375 |
| 28 | Ikan Badut | Air | 60 | 50 | 55 | 70 | 75 | 65 | 375 |
| 29 | Ikan Buntal Raksasa | Air/Racun | 75 | 60 | 85 | 65 | 70 | 40 | 395 |
| 30 | Kantong Semar Raksasa | Daun/Racun | 70 | 60 | 65 | 95 | 70 | 50 | 410 |

## Banding dengan Kategori

| Kategori | Rentang Total Tahap Final |
|----------|--------------------------:|
| Legendary | 590–595 |
| Pseudo-Legendary | 550–575 |
| Rare | 425–475 |
| Uncommon | 420–430 |
| Common | 360–410 |

## Contoh Perhitungan Skala (Line 3 Tahap — Rimau)

| Tahap | Skala | HP | ATK | DEF | SPA | SPD | SPE |
|-------|------:|---:|----:|----:|----:|----:|----:|
| Anak Rimau | ×0.60 | 48 | 72 | 45 | 39 | 42 | 66 |
| Rimau Muda | ×0.80 | 64 | 96 | 60 | 52 | 56 | 88 |
| Rimau Agung | ×1.00 | 80 | 120 | 75 | 65 | 70 | 110 |

## Rumus Stat Runtime (Level → Stat Aktual)

Dipakai saat battle (diimplementasikan di `game/scripts/core/nusamon_instance.gd`):

```
HP   = floor(2 * base * level / 100) + level + 10
Lain = floor(2 * base * level / 100) + 5
```

- `base` = stat hasil skala tahap evolusi di atas.
- Tanpa IV (keputusan GDD §4.4) — spesies sama selalu punya potensi sama.
- Contoh: Anak Rimau (HP base 48) di Lv.5 → floor(2×48×5/100) + 5 + 10 = **19 HP**; ATK base 72 → floor(2×72×5/100) + 5 = **12 ATK**.

## Catatan Balance

1. **Elang Garuda (SPE 145)** = monster tercepat; digantengi DEF moderat agar tidak mendominasi.
2. **Paus Samudra (HP 145)** = HP tertinggi; kompensasi SPE 60.
3. **Common (<400 total)** sengaja lemah — monster "langkah awal", bukan end-game.
4. Distribusi mengikuti peran: attacker tinggi di ATK/SPA, tank tinggi di HP/DEF, speedster tinggi di SPE.
5. Sumber kebenaran tunggal = `data/nusamons.json`; tabel ini adalah dokumentasi ringkasannya.
