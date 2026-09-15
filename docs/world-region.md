# Dunia & Region NUSAMON — v0.1

> **Region Nusantara** = satu region game berupa gugusan **6 pulau sub-region + Laut Nusantara** (laut transisi antar pulau).

## Prinsip Desain

1. **Pulau, bukan provinsi.** Batas laut = gating progresi alami; fauna tiap pulau otentik (Komodo hanya di Bali & Nusa Tenggara, Cenderawasih hanya di Maluku & Papua, Arwana di Kalimantan).
2. **Skala ringkas.** 1 pulau = 2-3 kota + 2-3 rute + 1 landmark. Total ±18 lokasi = kepadatan setara satu region Pokémon.
3. **Gating berlapis.** Laut ditempuh dengan perahu; kapal Laut Dalam terkunci sampai lencana tertentu.
4. **Positif & edukatif.** Kota menampilkan profesi/budaya lokal nyata; tanpa mistis/horor.

## 1. Peta Besar

| # | Pulau | Tema | Gym | Kunci Keluar |
|--:|-------|------|-----|--------------|
| 1 | **Jawa** | Desa, sawah, gunung api | G1 Normal · G2 Api | Tiket Kapal (setelah G2) |
| 2 | **Sumatra** | Rimba hujan, Danau Toba | G3 Daun · G4 Racun | Tiket Kapal (setelah G4) |
| 3 | **Kalimantan** | Sungai raksasa, hutan gambut | G5 Air | Perahu Selat (setelah G5) |
| 4 | **Sulawesi** | Pegunungan & teluk karang | G6 Petarung | Perahu (setelah G6) |
| 5 | **Bali & Nusa Tenggara** | Sabana, pesisir, Pulau Komodo | G7 Tanah | Perahu Laut Dalam (setelah G7) |
| 6 | **Maluku & Papua** | Hutan hujan, puncak bersalju | G8 Udara | Liga Nusantara (setelah G8) |
| — | **Laut Nusantara** | Rute laut, terumbu karang, palung | — (area encounter) | Item Perahu Laut Dalam |

**Catatan implementasi (Fase 5):** tabel khas final tiap rute = data/world.json (SSOT, divalidasi habitat via 	ools/validate.ps1); spesies laut hanya di Laut Nusantara; **starter & legendary tidak muncul liar** (bobot 0) — starter line lain diperoleh via Program Konservasi Prof. Candri (pasca-Juara).

## 2. Pulau per Pulau

### 2.1 Jawa — Area Pemula

| Lokasi | Keterangan | Encounter Khas |
|--------|-----------|----------------|
| Desa Sumberrejo | Kota pemula; Laboratorium Prof. Candri | — |
| Rute 1 (sawah) | Sawah & peternakan | Monyet Kecil, Rusa Muda, Ayam Jantan |
| **Kota Harapan** | G1 — Gym Normal | — |
| Rute 2 (kaki gunung) | Jalur naik ke gunung api | Ular Kecil, Ulat Daun, Monyet Kecil |
| **Kota Arunika** | G2 — Gym Api, kaki Gunung Kapi | — |

### 2.2 Sumatra — Rimba Hujan

| Lokasi | Keterangan | Encounter Khas |
|--------|-----------|----------------|
| Pelabuhan Bakau | Gerbang kapal dari Jawa | — |
| **Hutan Rimba** (landmark) | Hutan hujan lebat | Beruang Muda, Rangkong Muda, Ular Kecil, Monyet |
| **Kota Rimba** | G3 — Gym Daun | — |
| Rute 3 (pesisir timur) | Rawa & perairan payau | Buaya Kecil, Beruang Muda, Ular Kecil |
| **Kota Toba** (Danau Toba) | G4 — Gym Racun | — |

### 2.3 Kalimantan — Sungai Raksasa

| Lokasi | Keterangan | Encounter Khas |
|--------|-----------|----------------|
| Muara Kapuas | Gerbang dari Sumatra | — |
| Rute 4 (Sungai Kapuas) | Rute air panjang berkelok | Arwana Kecil, Udang Kecil, Buaya Kecil, Banteng Muda |
| **Hutan Gambut** (landmark) | Gambut lembap & gelap alami | Kantong Semar Kecil, Beruang Muda, Rangkong Muda, Banteng Muda |
| **Kota Kapuas** | G5 — Gym Air | — |

### 2.4 Sulawesi — Pegunungan & Teluk

| Lokasi | Keterangan | Encounter Khas |
|--------|-----------|----------------|
| Pelabuhan Anoa | Gerbang dari Kalimantan | — |
| Rute 5 (pegunungan) | Bukit & lembah | Babirusa Muda, Rusa Muda, Gurita Kecil |
| **Kota Maroso** | G6 — Gym Petarung | — |
| **Teluk Karang** (landmark) | Teluk biru berterumbu | Gurita Kecil, Kepiting Kecil, Rusa Muda |

### 2.5 Bali & Nusa Tenggara — Sabana

| Lokasi | Keterangan | Encounter Khas |
|--------|-----------|----------------|
| Kota Pura | Gerbang dari Sulawesi | — |
| Rute 6 (sabana Nipah) | Padang kering luas | Kakatua Muda, Rusa Muda, Monyet |
| **Kota Sabana** | G7 — Gym Tanah | — |
| **Pulau Komodo** (landmark) | Suaka satwa — habitat line Komodo | Biawak Kecil, Kakatua Muda, Monyet |

### 2.6 Maluku & Papua — Ujung Timur

| Lokasi | Keterangan | Encounter Khas |
|--------|-----------|----------------|
| Pelabuhan Cendana | Gerbang kapal laut dalam | — |
| **Hutan Cendana** (landmark) | Hutan hujan Papua; ada lorong rahasia | Ulat Daun, Kantong Semar Kecil |
| Rute 7 (pendakian) | Hutan → kabut → salju | Ulat Daun, Kantong Semar Kecil |
| **Kota Puncak** | G8 — Gym Udara + Liga Nusantara | — |
| **Puncak Salju** (landmark) | Puncak tertinggi Nusantara | — (event legendary) |

## 3. Delapan Gym

| # | Kota (Pulau) | Tipe | Leader | Profesi | Tim |
|--:|--------------|------|--------|---------|-----|
| G1 | Kota Harapan (Jawa) | Normal | **Bu Sari** | Peternak | Monyet Kecil Lv.8, Ayam Jantan Lv.10 |
| G2 | Kota Arunika (Jawa) | Api | **Pak Lesto** | Penjaga gunung api | Beruang Muda Lv.14, Ayam Satria Lv.16 |
| G3 | Kota Rimba (Sumatra) | Daun | **Pak Rimba** | Penjaga hutan | Ulat Daun Lv.17, Kantong Semar Kecil Lv.18, Orangkici Lv.19 |
| G4 | Kota Toba (Sumatra) | Racun | **Bu Tarra** | Apoteker herbal | Ikan Buntal Kecil Lv.20, Ular Kecil Lv.21, Ular Raksasa Lv.23 |
| G5 | Kota Kapuas (Kalimantan) | Air | **Bang Riang** | Nakhoda perahu | Lumba Kecil Lv.24, Arwana Kecil Lv.25, Buaya Kecil Lv.26 |
| G6 | Kota Maroso (Sulawesi) | Petarung | **Guru Rahman** | Pelatih pencak silat | Babirusa Muda Lv.27, Gurita Raksasa Lv.28, Banteng Murba Lv.29 |
| G7 | Kota Sabana (Bali & NT) | Tanah | **Pak Rida** | Konservasionis Komodo | Kepiting Kenari Lv.31, Badak Muda Lv.32, Komodo Lv.33 |
| G8 | Kota Puncak (Papua) | Udara | **Ibu Waigeo** | Pengamat burung | Kakatua Raja Lv.35, Merak Agung Lv.36, Rangkong Agung Lv.37 |

## 4. Liga Nusantara — Elite Empat & Juara

Di Kota Puncak (Papua), syarat: **8 lencana**.

| Urutan | Nama | Tema | Profesi | Tim |
|--------|------|------|---------|-----|
| E1 | **Kak Dinda** | Listrik | Ahli meteorologi | Ayam Satria Lv.40, Lumba Petir Lv.42 |
| E2 | **Pak Nandra** | Naga | Pembudidaya arwana | Hiu Raksasa Lv.42, Arwana Naga Lv.44 |
| E3 | **Bu Waja** | Baja | Pandai besi | Kepiting Kenari Lv.43, Badak Baja Lv.45 |
| E4 | **Kapten Samudra** | Air | Kapal penelitian laut | Gurita Raksasa Lv.44, Buaya Raksasa Lv.45, Hiu Raksasa Lv.46 |
| **Juara** | **Nara** | Campuran | Penjelajah samudra | Merak Agung Lv.47, Gajah Raksasa Lv.48, Arwana Naga Lv.48, Rimau Agung Lv.50, Komodo Raja Lv.50 |

## 5. Lokasi Legendary — Trio Penjaga Nusantara

| Nusamon | Lokasi | Syarat Akses | Aturan |
|---------|--------|--------------|--------|
| **Paus Samudra** | Palung Nusantara (titik terdalam Laut Nusantara) | Perahu Laut Dalam | 1 encounter per save |
| **Cenderawasih Agung** | Lorong rahasia Hutan Cendana (Papua) | Setelah G8 | 1 encounter per save |
| **Elang Garuda** | Puncak Salju | Setelah G8 | 1 encounter per save |

> **Narasi Trio Penjaga** (positif, tanpa okultisme): satwa-satwa langka yang menjaga keseimbangan ekosistem — Paus menjaga kedalaman laut, Cenderawasih menjaga hutan, Elang menjaga langit. Terinspirasi konservasi nyata.

## 6. Alur Progresi (Gate Flow)

```
Mulai (Desa Sumberrejo)
→ G1 → G2 → [Tiket Kapal] → Sumatra
→ G3 → G4 → [Tiket Kapal] → Kalimantan
→ G5 → [Perahu Selat] → Sulawesi
→ G6 → [Perahu] → Bali & Nusa Tenggara
→ G7 → [Perahu Laut Dalam] → Maluku & Papua
→ G8 → Liga Nusantara → Juara Nara
→ Endgame: Trio Penjaga + Program Konservasi (starter lain) + Nusadex 100%
```

## 7. Catatan MVP

- MVP hanya membangun **Jawa**: Desa Sumberrejo → Rute 1 → Kota Harapan (G1) → Rute 2 → Kota Arunika (G2) — sesuai GDD §8.
- Pulau lain: konten dikunci hingga vertical slice selesai (prevents scope creep).
- Data habitat tiap spesies sudah tersedia di `data/nusamons.json` → field `habitatPulau`.

## 8. Catatan: Peta Fiksi, Bukan Peta Asli

Region game **menempel pada kerangka geografi Indonesia** (urutan & posisi relatif pulau sama; landmark nyata sebagai inspirasi nama/tema) tetapi memakai nama dan tata letak fiksi. Alasannya **kreatif & teknis, bukan legal-IP**:

1. **Kontrol pacing & gating** — kompresi geografi (1 pulau = 2-3 kota + 2-3 rute, prinsip desain §2) menjaga densitas konten dan menjadikan batas laut gate progresi yang alami.
2. **Kebebasan akurasi** — lokasi bisa dipindah/dikompres demi gameplay tanpa dibebani ekspektasi akurasi dari pemain yang hafal peta asli.
3. **Lisensi data & performa** — data peta nyata tidak bebas dipakai (ToS Google Maps melarang ekstraksi data ke engine lain; OSM mewajibkan atribusi & share-alike ODbL), dan geometri peta asli berat untuk 3D low-poly di Web (ADR-02/ADR-04).

> **Klarifikasi:** nama geografis nyata **tidak** menimbulkan risiko IP bila disebut dalam karya fiksi — pilihan nama fiktif murni keputusan kreatif (design pillar #1: originalitas konten), bukan mitigasi hukum.

