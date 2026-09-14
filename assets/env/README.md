# Model environment CC0 — NUSAMON (Fase 3 langkah 6)

Environment dunia (desa, rute, kota, gunung) menggunakan aset low-poly dari
**pustaka CC0** sesuai GDD §7 / ADR-02/03. Monster tetap dibuat custom via
`tools/blender`; environment TIDAK dibuat custom — diambil dari pustaka siap pakai.

## Sumber pustaka (CC0 — bebas dipakai komersial, tanpa atribusi wajib)

| Pustaka | Paket yang relevan | URL |
|---|---|---|
| Kenney | Nature Kit, City Kit, Fantasy Town Kit | https://kenney.nl/assets |
| Quaternius | Nature Pack, Buildings Pack | https://quaternius.com |

> Verifikasi lisensi di halaman unduh masing-masing paket (semuanya CC0 saat
> dokumen ini ditulis). Simpan salinan lisensi paket di folder ini bila berubah.

## Cara memasang

1. Unduh paket (format glTF/GLB).
2. Salin/ekspor model gabungan per lokasi ke folder ini dengan penamaan
   `<id_lokasi>.glb` (sama dengan field `id` di `data/world.json`):

```
assets/env/desa_sumberrejo.glb
assets/env/rute_1.glb
assets/env/kota_harapan.glb
assets/env/rute_2.glb
assets/env/kota_arunika.glb
```

3. Buka kembali game — `EnvBuilder.pasang()` otomatis memakai `.glb`
   (`ResourceLoader.exists`), tanpa perubahan kode.

## Fallback placeholder

Sampai aset dipasang, tiap lokasi memakai **placeholder low-poly programatik**
(`game/world/env_builder.gd`): tanah berwarna tema + props sederhana
(rumah/petak sawah/gedung/Gunung Kapi/pohon). Warna mengikuti palet tropis GDD §7.
Placeholder deterministik dan diuji headless (`game/tests/test_env.gd`).