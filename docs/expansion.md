# Ekspansi Franchise — TCG, Mobile, Spin-off — v0.1

> **Prinsip utama: Core dulu.** Semua ekspansi hanya berjalan setelah vertical slice main game selesai. Ekspansi = amplifikasi IP, bukan pengganti core.

## 1. Posisi Ekspansi dalam Roadmap

| Fase Proyek | Ekspansi Diizinkan? |
|-------------|---------------------|
| Fase 0–4 (GDD → Vertical Slice) | ❌ Tidak — fokus penuh ke core |
| Fase 5+ (Produksi penuh) | 🟡 Studi kelayakan |
| Setelah rilis core | ✅ Produksi ekspansi |

## 2. Kartu NUSAMON (Nusa-TCG)

Game kartu koleksi yang memakai ulang aset desain core:

| Elemen Kartu | Sumber Data |
|--------------|-------------|
| Nama, Tipe (11 tipe) | Sama dengan game — pemain tidak belajar ulang |
| HP, Move (power/akurasi) | `data/nusamons.json` + `data/moves.json` |
| Rarity & Tahap Evolusi | Kategori roster yang sama |

- **Aturan inti (sketsa):** setiap Nusamon aktif 1 vs 1; tumpukan kartu energi tipe; kartu tahap 2 ditaruh *di atas* kartu tahap 1 (mekanik evolusi kartu klasik); type chart game berlaku penuh.
- **Keunggulan desain:** satu type chart + satu dataset JSON melayani game digital & TCG (data tunggal, dua produk).

## 3. Mobile — "Nusamon Petualang" (Location-Based)

Konsep ala Pokémon GO dengan kearifan lokal:

- **Encounter berbasis habitat nyata:** pantai → spesies Air; taman kota → Common (Monyet, Ayam); pegunungan → Udara/Tanah.
- **AR snapshot** + mode edukasi konservasi (info fauna asli, status perlindungan).
- **Pertimbangan teknis:** izin lokasi, hemat baterai, keamanan pemain (pengingat lingkungan), aksesibilitas tanpa GPS.

## 4. Spin-off Potensial (Studi Kelayakan)

| Ide | Genre | Catatan |
|-----|-------|---------|
| Nusamon Rumble | Action arena | Memanfaatkan move set yang sudah ada |
| Nusamon Penyelamat | Puzzle/adventure konservasi | Sudut edukasi lingkungan paling kuat |
| Nusamon Dungeon | Roguelike grid | Menggunakan type chart & stats apa adanya |
| Nusamon Ranch | Casual/koleksi | Untuk audiens paling muda |

## 5. Risiko & Prinsip Ekspansi

1. **Fokus:** ekspansi yang dibuat terlalu dini membatalkan core. Disiplin pada roadmap §1.
2. **Konsistensi data:** semua ekspansi WAJIB membaca dataset JSON yang sama (single source of truth).
3. **Lisensi aman:** seluruh IP original berbasis fauna → bebas untuk merch/kartu/mobile.
4. **Budaya positif:** spin-off pun dilarang memasukkan elemen mistis/horor.
