# Audio NUSAMON — Placeholder & Aset CC0 (Fase 5 langkah 5)

Sistem audio aktif via **`AudioManager`** (static, konvensi engine lain) + SSOT
**`data/audio.json`** (id / file / volume / loop). Saat ini folder ini memuat
**placeholder terprogram** (`tools/audio/generate_sfx.py`): suara
"gamelan-ambient" sintesis deterministik (strike envelope + overtone lonceng,
skala slendro-approksimasi) — memadai untuk playtest, bukan audio final.

## Ganti dengan aset asli (tanpa ubah kode)

Semua file dipakai lewat path di `data/audio.json` — cukup ganti file-nya
(perhatikan **ukuran total ≤ 15–20 MB** untuk export Web, ADR-04):

| Item | Sumber direkomendasikan (lisensi aman untuk komersial & ekspansi) |
|---|---|
| BGM | **Sonniss GDC Bundle** (royalty-free, gratis) · **OpenGameArt CC0** · aransemen sendiri dari sample instrument legal (komposisi original = IP murni) |
| SFX | **Kenney Audio** (CC0) · **FreeSound.org filter CC0** · Sonniss |

Aturan lisensi (konsisten `docs/expansion.md`): hanya CC0/royalty-free atau
komposisi original milik proyek. **Jangan** menyampling rekaman gamelan
komersial tanpa lisensi. Simpan salinan lisensi paket di folder ini bila
pustaka menuntut atribusi.

## Konvensi file

- BGM: `.ogg` (looping, ukuran kecil) — `bgm_<pulau>.ogg`, `bgm_battle.ogg`,
  `bgm_liga.ogg`
- SFX/jingle/sting: `.wav` pendek atau `.ogg`
- Nama file bebas; yang penting field `file` di `data/audio.json` menunjuk
  file yang benar (validator `tools/validate.ps1` memeriksa keberadaannya)

## Regenerasi placeholder

```bash
python tools/audio/generate_sfx.py --id all --out assets/audio
```

Deterministik — hasil identik setiap dijalankan. Setelah menambah/mengganti
file, jalankan sekali: `godot --headless --path . --import` agar aset baru
terimpor sebelum tes headless.
