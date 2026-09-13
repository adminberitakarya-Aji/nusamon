# Gameplay Depth — Ability, Sifat, Item Tangkap, EXP — v0.1

> Melengkapi GDD §4. Dokumen ini mengunci keputusan sistem "depth" untuk MVP.

## 1. Ability — "Kemampuan" Pasif

**Prinsip: 1 kemampuan pasif per spesies** (berlaku di semua tahap evolusi). Efek sederhana, terlihat in-game, tanpa tema okultisme.

| ID Ability | Nama | Efek | Analog Pokémon |
|------------|------|------|----------------|
| taring_tajam | Taring Tajam | ATK fisik ×1.5 saat HP ≤ 1/3 | Blaze/Guts |
| panen_subur | Panen Subur | Pulihkan 12.5% HP per giliran saat HP ≤ 1/3 | Healer |
| napas_dalam | Napas Dalam | SPA ×1.5 saat HP ≤ 1/3 | Torrent |
| pelindung_karang | Pelindung Karang | DEF +1 tahap saat masuk battle | Shell Armor+ |
| mata_elang | Mata Elang | Akurasi move pengguna selalu 100% | No Guard (satu sisi) |
| kulit_tebal | Kulit Tebal | Damage serangan fisik diterima −10% | Thick Fat |
| refleks_kilat | Refleks Kilat | 10% peluang menghindari serangan | Anticipation |
| cengkeraman_kuat | Cengkeraman Kuat | Lawan tidak dapat bertukar/kabur selama pengguna aktif | Shadow Tag |
| racun_alami | Racun Alami | Lawan yang menyerang fisik ke pengguna 30% teracuni | Poison Point |
| serbuk_sari | Serbuk Sari | Lawan yang menyentuh pengguna secara fisik 30% mengantuk | Effect Spore |
| madu_manis | Madu Manis | Lawan yang menyentuh pengguna secara fisik 30% terpikat (50% gagal menyerang) | Cute Charm |
| tiruan_suara | Tiruan Suara | Saat masuk battle, ATK lawan turun 1 tahap | Intimidate |

### Pemetaan Ability → Spesies

| Ability | Spesies (alasan tematik) |
|---------|--------------------------|
| taring_tajam | Rimau, Hiu, Buaya, Banteng, Arwana, Ayam, Udang (gigi/cakar/tanduk) |
| panen_subur | Orangutan (hijau = regenerasi hutan) |
| napas_dalam | Cenderawasih Agung (napas fajar) |
| pelindung_karang | Penyu, Badak, Babirusa (cangkang/zirah) |
| mata_elang | Elang Garuda, Rangkong (penglihatan tajam) |
| kulit_tebal | Paus Samudra, Gajah, Ikan Badut (kulit tebal nyata) |
| refleks_kilat | Lumba-lumba, Rusa, Monyet (gesit) |
| cengkeraman_kuat | Gurita, Kepiting (cengkeraman nyata) |
| racun_alami | Komodo, Ular, Ikan Buntal, Kantong Semar (racun nyata sains) |
| serbuk_sari | Kupu-kupu (serbuk bunga) |
| madu_manis | Beruang Madu, Merak (daya tarik) |
| tiruan_suara | Kakatua (meniru suara nyata) |

## 2. Sifat (Nature) — KEPUTUSAN: TIDAK ADA DI MVP

- **Tidak ada Nature berpengaruh stat** di MVP. Alasan: mengurangi RNG frustrasi, mencegah meta grinding, dan menjaga battle tetap fair bagi pemain kasual.
- Opsional di fase 2: **Sifat kosmetik** (Nakal, Pemberani, Pemalu, Berisik...) — hanya flavor text & dialog kecil, **nol efek stat**.
- **IV juga tidak ada** (sudah diputuskan di GDD §4.4) — semua Nusamon spesies yang sama punya potensi dasar sama; variasi datang dari level + Latihan.

## 3. Item Tangkap — "Amukan"

| Item | Bonus (BallBonus) | Ketersediaan |
|------|------------------:|--------------|
| **Amukan** | ×1.0 | Toko, murah (awal game) |
| **Amukan Kuat** | ×1.5 | Toko, setelah G1 |
| **Amukan Super** | ×2.0 | Toko, setelah G3 |
| **Amukan Nusantara** | ×3.0 | Hadiah event/rahasia (langka) |

Rumus tangkap (GDD §4.3): `a = ((3*MaxHP - 2*CurHP) * CatchRate * BallBonus) / (3*MaxHP)` plus modifier status:
- Tidur / Racun → **×2.0**
- Kelumpuhan → **×1.5**
- Luka Bakar → ×1.0 (tidak membantu)

## 4. Encounter Rate per Rarity

| Rarity | Bobot kemunculan di rute sesuai habitat | CatchRate (0–255) |
|--------|----------------------------------------:|------------------:|
| Common | 60% | 190 |
| Uncommon | 25% | 120 |
| Rare | 12% | 75 |
| Pseudo-Legendary | 3% | 45 |
| Legendary | Event (bukan random) | 5 |
| Starter | Tidak ada di alam (hanya event) | 45 |

- Lokasi encounter ditentukan field `habitatPulau` di `data/nusamons.json`.
- Detail per spesies (catchRate, ability, learnset): `data/nusamons.json` → `detailSpesies`.

## 5. Kurva EXP — Medium-Fast

- Total EXP untuk mencapai level `L`: **L³** (medium-fast, standar dan mudah dipahami).

| Level | 5 | 10 | 20 | 30 | 40 | 50 | 60 | 70 | 80 | 90 | 100 |
|-------|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|
| Total EXP | 125 | 1.000 | 8.000 | 27.000 | 64.000 | 125.000 | 216.000 | 343.000 | 512.000 | 729.000 | 1.000.000 |

- **EXP gain per kemenangan:** `floor(baseExpYield × levelLawan ÷ 7) × (1.5 jika battle trainer, ×1.0 wild)`.
- **baseExpYield per rarity (tahap final):** Common 55 · Uncommon 72 · Rare 90 · Pseudo-Legendary 115 · Legendary 170 · Starter 62. Tahap sebelumnya = `round(yield × skala tahap)`.
- **Evolution level standar:** line 3-tahap = Lv.16 & Lv.36; line 2-tahap = Lv.22; Legendary tidak berevolusi.
  → Sudah tersedia sebagai field **`lvEvolusi`** di `data/nusamons.json` (tiap tahapan).
- **Bonus evolusi:** saat berevolusi, HP bertambah sebesar nilai HP yang "hilang" akibat perubahan MaxHP (mengikuti konvensi Pokémon).

## 6. Latihan (EV-lite) — Transparan & Terbatas

- Setiap kemenangan memberi **1 Poin Latihan** untuk stat yang paling banyak digunakan di battle tersebut (maks. 1 poin per battle).
- **Batas:** total 50 poin per Nusamon; maksimal 25 poin per satu stat.
- **Konversi:** setiap 4 poin = **+1 stat final** pada Level 100 (dibulatkan).
- **Reset:** item **"Teh Herba"** menghapus semua poin Latihan (strategi bisa diubah ulang).
- Semua angka ini **terlihat di UI** (layar status) — pemain tidak perlu wiki eksternal.
