# Blender Generator Aset NUSAMON

Generator model 3D low-poly **terprogram** (tanpa modeling manual). Sesuai ADR-03 di `docs/tech-stack.md`.

## Prasyarat

- **Blender 3.6 LTS atau 4.x** (menggunakan API stabil: primitif + export glTF)
- Blender **belum wajib** di mesin semua kontributor — hanya yang menjalankan generator

## Cara Menjalankan (Headless)

```bash
# Semua spesies MVP tahap dasar yang tersedia di framework:
blender --background --python tools/blender/nusamon_build.py -- --species all --out assets/models

# Spesies tertentu (id dipisah koma):
blender --background --python tools/blender/nusamon_build.py -- --species anak_rimau,orangkici

# Hanya 3 starter tahap dasar (shortcut):
blender --background --python tools/blender/starter.py
```

> Di Windows, `blender` harus ada di PATH atau gunakan path lengkap, contoh:
> `& "C:\Program Files\Blender Foundation\Blender 4.3\blender.exe" --background --python tools\blender\nusamon_build.py -- --species all`

Output: `assets/models/<id>.glb` (glTF Binary — Godot mengimpor otomatis).

## Konvensi Model

1. Nama file = ID tahapan snake_case (`anak_rimau.glb`, `monyet_emas.glb`)
2. Origin di (0,0,0); model berdiri di lantai z=0
3. Menghadap **-Y** (arah depan kamera battle)
4. Material warna flat (Principled BSDF, roughness ~0.9), tanpa tekstur di MVP
5. Satu root Empty sebagai parent seluruh part
6. Generator **deterministik** — jalankan ulang menghasilkan model identik

## Menambah Spesies Baru

1. Buka `nusamon_build.py`
2. Tulis fungsi `build_<id>` memakai helper: `clear_scene, material, root_empty, attach, add_box, add_cyl, add_ico, add_cone, add_eyes`
3. Daftarkan di dict `BUILDERS`
4. Jalankan headless + periksa hasil di Godot
