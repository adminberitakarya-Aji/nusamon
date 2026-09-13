# Nusadex — Desain & Deskripsi Entri — v0.1

## 1. Konsep

**Nusadex** = ensiklopedia digital 30 spesies Nusamons. Dua peran: **progres koleksi** (kompletesisme) dan **edukasi fauna** (deskripsi berbasis fakta nyata).

## 2. Alur Pengisian

| Kejadian | Efek di Nusadex |
|----------|-----------------|
| Melihat Nusamon liar | Entri tercatat: siluet + nama |
| Menangkap | Entri lengkap: sprite, stat, deskripsi |
| Berevolusi / melihat tahap baru | Tahap evolusi bertambah di chain |
| 30/30 lengkap | Lencana "Nusadex Lengkap" + hadiah endgame |

- Item **Nusadex Mini** diberikan Prof. Candri di Desa Sumberrejo (prolog).

## 3. UI (2 Layar)

### 3.1 Layar Daftar
- Grid kartu: **siluet gelap** (belum tangkap) atau **sprite penuh** (sudah), nomor #, nama, ikon tipe.
- Filter: Semua / Tertangkap / Per Pulau / Per Rarity / Per Tipe.
- Progress bar "X/30" di header.

### 3.2 Layar Detail
- Sprite besar + nama + **chain evolusi visual** (tahap yang belum terlihat = tanda tanya).
- Ikon tipe · ikon **habitat pulau** · bar 6 stat (hanya jika tertangkap).
- Deskripsi teks (1–2 kalimat, lihat §5).
- Tombol **"Tampilkan di Peta"** — sorot pulau habitat di world map (mengajak eksplorasi).

## 4. Aturan Konten Deskripsi

- 1–2 kalimat per spesies: **fakta fauna nyata** + sentuhan fantasi ringan.
- Tanpa horor/okultisme. Deskripsi sama dipakai semua tahap evolusi spesies tsb.
- Sumber data: `data/nusamons.json` (field `deskripsi` — diisi saat implementasi data game).

## 5. Deskripsi 30 Entri

| # | Spesies | Deskripsi |
|--:|---------|-----------|
| 1 | Rimau | Harimau Sumatra asli; pola belangnya sempurna menyamar di rimba, lakunya menggetarkan dedaunan seperti guntur kecil. |
| 2 | Orangutan | Arsitek hutan Sumatra & Kalimantan; tangan panjangnya menyusun sarang raksasa di kanopi pohon. |
| 3 | Penyu | Pelaut sejati Nusantara; berpuluh tahun kemudian ia selalu pulang ke pantai tempat dilahirkan. |
| 4 | Elang | Penjaga langit; siluet sayapnya terinspirasi burung Garuda, lambang kebanggaan bangsa. |
| 5 | Cenderawasih | "Manuk paradiso" dari Papua; ekornya menyala seperti fajar di hutan hujan. |
| 6 | Paus | Raksasa lembut samudra; lagu rendahnya menggema di palung terdalam. |
| 7 | Komodo | Naga asli Indonesia; gigitannya mengandung racun alami, hanya hidup di beberapa pulau kecil. |
| 8 | Gajah | Penjaga hutan; jejak telapak kakinya menjadi kolam kecil tempat hewan kecil minum. |
| 9 | Badak | Pemalu berzirah; kulit berlipatnya seperti baju baja alami, tanduknya keras seperti perkakas. |
| 10 | Hiu | Pelari laut sejati; ia tidak pernah benar-benar berhenti berenang seumur hidupnya. |
| 11 | Buaya | Penguasa muara; rahangnya tercatat sebagai salah satu yang terkuat di Nusantara. |
| 12 | Banteng | Pejuang tanduk; punggungnya melengkung seperti bukit saat siap menghantam. |
| 13 | Babirusa | "Rusa-babi" legendaris Sulawesi; gading atasnya melengkung keluar seperti mahkota pedang. |
| 14 | Beruang Madu | Pendaki pohon berdada emas; hidungnya tajam mencium aroma madu dari jarak jauh. |
| 15 | Rangkong | Petani hutan; biji buah yang dimakannya disebar kembali — penyebar benih yang rajin. |
| 16 | Merak | Sang mahkota seribu mata; menarinya memutar roda kilauan hijau-biru. |
| 17 | Lumba-lumba | Kilau listrik di laut; selalu bermain di haluan perahu nelayan. |
| 18 | Arwana | "Ikan naga" dari sungai Kapuas; sisiknya berkilau seperti uang kuno. |
| 19 | Gurita | Ahli teknik delapan lengan; pandai menyusup ke celah karang dan mengunci lawan. |
| 20 | Kakatua | Sang peniru; mampu meniru ratusan suara, dari derit pintu hingga nyanyian burung lain. |
| 21 | Ular | Pembaca getaran; lidah bercabangnya mengecap udara untuk menemukan jejak hangat. |
| 22 | Rusa | Pelari hutan; bertolusnya tumbuh megah tiap musim seperti mahkota baru. |
| 23 | Monyet | Penari pohon yang nakal; jago memanjat dan selalu penasaran dengan bawaan pengelana. |
| 24 | Ayam | Leluhur ayam hutan merah; jengger merahnya menyala, simbol keberanian. |
| 25 | Kupu-kupu | Bunga yang terbang; sayap hitam-keemasannya menjuntai anggun seperti ekor walet. |
| 26 | Udang | Pukul tercepat di terumbu; kakinya menyambar seperti petir kecil. |
| 27 | Kepiting | Sang peranti baju; cangkang barunya makin tebal tiap rontok, capainya mampu memecah kelapa. |
| 28 | Ikan Badut | Kartunis terumbu; hidup berdampingan aman dengan anemon yang menyengat — untung bersama. |
| 29 | Ikan Buntal | Balon beracun; menggembung saat takut — licik, tapi sayang jangan dimakan! |
| 30 | Kantong Semar | Perangkap manis; kantongnya berisi cairan yang menjebak serangga yang datang. |
