# Type Chart NUSAMON — 11 Tipe

> Baris = tipe **penyerang** (move), kolom = tipe **pertahanan** (Nusamon target).
> `2` = efektif (×2) · `½` = kurang efektif (×0.5) · `0` = tidak berefek (×0) · kosong/`1` = netral.

## Matriks Efektivitas

| ⚔️ \ 🛡️ | Api | Air | Daun | Tanah | Udara | Normal | Listrik | Racun | Petarung | Naga | Baja |
|----------|----:|----:|-----:|------:|------:|-------:|--------:|------:|---------:|-----:|-----:|
| **Api**      | ½ | ½ | 2 | ½ | 1 | 1 | 1 | 1 | 1 | ½ | 2 |
| **Air**      | 2 | ½ | 1 | 2 | 1 | 1 | 1 | 1 | 1 | ½ | 1 |
| **Daun**     | 1 | 2 | ½ | 2 | ½ | 1 | 1 | ½ | 1 | ½ | ½ |
| **Tanah**    | 2 | 1 | ½ | 1 | 0 | 1 | 2 | 2 | 1 | 1 | 2 |
| **Udara**    | 1 | 1 | 2 | 1 | ½ | 1 | ½ | 1 | 2 | ½ | ½ |
| **Normal**   | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | ½ |
| **Listrik**  | 1 | 2 | ½ | 0 | 2 | 1 | ½ | 1 | 1 | ½ | 1 |
| **Racun**    | 1 | 1 | 2 | ½ | 1 | 2 | 1 | ½ | 1 | 1 | 0 |
| **Petarung** | 1 | 1 | 1 | 1 | ½ | 2 | 1 | 1 | ½ | ½ | 2 |
| **Naga**     | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 2 | ½ |
| **Baja**     | ½ | ½ | 2 | 1 | 1 | 1 | ½ | 1 | 1 | 2 | ½ |

## Logika Desain (Narasi Alam)

- **Api** membakar Daun & melelehkan Baja; padam oleh Air dan Tanah.
- **Air** memadamkan Api & mengikis Tanah; diserap Daun.
- **Daun** tumbuh dari Air & Tanah; mudah terbakar, diterbangkan Udara.
- **Tanah** memadamkan Api, **membuat Listrik "grounded" (0)**, menyerap Racun, dan merusak Baja; **tidak bisa menyentuh Udara (0)**.
- **Udara** menghantam Daun & Petarung (pukulan melayang); tahan Tanah (immune terbalik).
- **Listrik** menembus Air & menjatuhkan Udara; ter-grounded oleh Tanah.
- **Racun** merusak Daun & makhluk Normal; Baja **kebal (0)**, Tanah menyerapnya.
- **Petarung** menghantam Normal & menempa Baja; sulit mengenali yang melayang.
- **Naga** hanya rapuh pada dirinya sendiri dan Baja — tipe "elite" yang tahan banyak elemen.
- **Baja** pertahanan super: kebal Racun, menahan banyak tipe; rapuh oleh Api, Tanah, Petarung.

## Ringkasan Kolumn (Sisi Pertahanan)

| Tipe Pertahanan | Rentan (2× dari) | Tahan (½ dari) | Kebal (0 dari) |
|-----------------|------------------|----------------|----------------|
| Api | Air, Tanah | Api, Baja | — |
| Air | Daun, Listrik | Air | — |
| Daun | Api, Udara, Baja | Air, Daun, Racun, Naga, Baja | — |
| Tanah | Air, Daun | Tanah | Listrik |
| Udara | Listrik | Daun, Petarung, Udara, Naga, Baja | Tanah |
| Normal | Racun, Petarung | — | — |
| Listrik | Tanah | Udara, Listrik, Baja | — |
| Racun | Tanah, Daun | Racun | Baja |
| Petarung | Udara | Petarung, Naga | — |
| Naga | Naga, Baja | Api, Air, Daun, Udara, Listrik, Petarung | — |
| Baja | Api, Tanah, Petarung, Baja | Daun, Udara, Normal, Listrik, Naga, Baja | Racun |

## Catatan Balance

1. **Naga & Baja** sengaja langka (2 dan 1 spesies) sebagai tipe premium — keduanya kuat di pertahanan.
2. **Normal** sengaja polos: tanpa kebalan, jadi "baseline" bagi pemula (Monyet, Rusa).
3. Semua tipe punya minimal 1 kelemahan ofensif utama; tidak ada tipe "tanpa counter".
4. Chart ini turunan langsung dari `data/type-chart.json` — jika diubah, ubah JSON dulu (single source of truth).
