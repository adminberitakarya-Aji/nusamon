# tools/blender/nusamon_build.py
"""
NUSAMON — Asset Builder: generator model 3D low-poly (terprogram).

Cara pakai (headless):
    blender --background --python tools/blender/nusamon_build.py -- \
        --species anak_rimau,orangkici --out assets/models

Konvensi (lihat docs/tech-stack.md):
- Model dari primitif (box/cylinder/icosphere/cone), material warna flat tanpa tekstur
- Berpusat di origin, berdiri di lantai z=0, menghadap -Y (depan kamera battle)
- Satu root Empty sebagai parent semua part
- Deterministik: hasil identik setiap dijalankan
"""

import argparse
import os
import sys

import bpy

OUTPUT_DIR = "assets/models"


# ---------------------------------------------------------------- util dasar

def clear_scene():
    """Bersihkan seluruh objek scene (idempotent)."""
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def material(name, color, rough=0.9):
    """Material warna flat (Principled BSDF)."""
    m = bpy.data.materials.get(name)
    if m is None:
        m = bpy.data.materials.new(name)
        m.use_nodes = True
        bsdf = m.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = (
            color[0], color[1], color[2], 1.0)
        bsdf.inputs["Roughness"].default_value = rough
    return m


def root_empty(name):
    """Root Empty sebagai parent seluruh part model."""
    bpy.ops.object.empty_add(type="PLAIN_AXES", location=(0, 0, 0))
    obj = bpy.context.active_object
    obj.name = name
    return obj


def attach(root, obj):
    obj.parent = root
    return obj


def add_box(name, size, loc, mat, rot=(0, 0, 0)):
    """Kubus low-poly; size = (x, y, z) penuh."""
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    o.data.materials.append(mat)
    return o


def add_cyl(name, radius, depth, loc, mat, rot=(0, 0, 0), verts=8):
    """Silinder low-poly (segi-8)."""
    bpy.ops.mesh.primitive_cylinder_add(
        radius=radius, depth=depth, vertices=verts, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(mat)
    return o


def add_ico(name, radius, loc, mat, subdiv=1, scale=(1, 1, 1)):
    """Icosphere (bola low-poly); scale untuk bentuk lonjong/pipih."""
    bpy.ops.mesh.primitive_ico_sphere_add(
        subdivisions=subdiv, radius=radius, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    o.data.materials.append(mat)
    return o


def add_cone(name, radius, depth, loc, mat, rot=(0, 0, 0), verts=8):
    """Kerucut low-poly (telinga, paruh, ekor)."""
    bpy.ops.mesh.primitive_cone_add(
        radius1=radius, depth=depth, vertices=verts, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(mat)
    return o


def add_eyes(root, xs, z, mat_dark, r=0.045, offset=(0.0, 0.0)):
    """Sepasang mata kecil (default menghadap +X)."""
    for y in xs:
        loc = (offset[0] + r, y, offset[1] + z)
        attach(root, add_ico("mata", r, loc, mat_dark, subdiv=1))


# ---------------------------------------------------------------- spesies

def build_anak_rimau():
    """Rimau tahap 1: anak harimau gemuk, belang, ekor pendek."""
    clear_scene()
    oranye = material("rimau_oranye", (0.90, 0.45, 0.12))
    krem = material("rimau_krem", (0.95, 0.85, 0.68))
    gelap = material("rimau_gelap", (0.18, 0.11, 0.08))
    root = root_empty("anak_rimau")
    # badan + kepala + moncong
    attach(root, add_box("badan", (1.1, 0.62, 0.58), (0, 0, 0.62), oranye))
    attach(root, add_box("kepala", (0.6, 0.56, 0.52), (0.72, 0, 0.98), oranye))
    attach(root, add_box("moncong", (0.22, 0.3, 0.2), (1.02, 0, 0.86), krem))
    # telinga
    for y in (-0.2, 0.2):
        attach(root, add_cone("telinga", 0.09, 0.16, (0.55, y, 1.28), oranye))
    # mata
    add_eyes(root, (-0.14, 0.14), 1.05, gelap, offset=(0.9, 0))
    # 4 kaki
    for x in (0.38, -0.38):
        for y in (-0.22, 0.22):
            attach(root, add_box("kaki", (0.18, 0.16, 0.34), (x, y, 0.17), oranye))
    # belang (garis gelap badan)
    for i, x in enumerate((-0.35, -0.1, 0.15, 0.4)):
        attach(root, add_box("garis", (0.05, 0.66, 0.5), (x, 0, 0.66 + (i % 2) * 0.04), gelap))
    # ekor + ujung gelap
    attach(root, add_cyl("ekor", 0.06, 0.8, (-0.75, 0, 0.75), oranye, rot=(0, 1.2, 0)))
    attach(root, add_ico("ekor_ujung", 0.07, (-1.05, 0, 1.05), gelap))


def build_orangkici():
    """Orangutan tahap 1: bayi kecil, badan bulat, lengan panjang."""
    clear_scene()
    merah = material("orang_merah", (0.62, 0.32, 0.14))
    krem = material("orang_kulit", (0.85, 0.66, 0.5))
    gelap = material("mata_gelap", (0.12, 0.08, 0.06))
    root = root_empty("orangkici")
    # badan duduk bulat + perut krem
    attach(root, add_ico("badan", 0.5, (0, 0, 0.55), merah, subdiv=2, scale=(1, 0.8, 1.05)))
    attach(root, add_ico("perut", 0.34, (0.14, 0, 0.5), krem, subdiv=2))
    # kepala besar + wajah datar
    attach(root, add_ico("kepala", 0.42, (0.42, 0, 1.15), merah, subdiv=2))
    attach(root, add_ico("wajah", 0.3, (0.62, 0, 1.1), krem, subdiv=2, scale=(0.6, 1, 0.8)))
    add_eyes(root, (-0.15, 0.15), 1.18, gelap, r=0.05, offset=(0.62, 0))
    # lengan panjang (ciri orangutan)
    for y in (-0.45, 0.45):
        attach(root, add_cyl("lengan", 0.11, 0.9, (0.05, y, 0.55), merah, rot=(1.3, 0, 0)))
    # kaki pendek
    for y in (-0.25, 0.25):
        attach(root, add_cyl("kaki", 0.13, 0.35, (-0.15, y, 0.16), merah))


def build_penyuci():
    """Penyu tahap 1: anak penyu, tempurung kubah, sirip pipih."""
    clear_scene()
    kerang = material("penyu_kerang", (0.25, 0.7, 0.5))
    hijau = material("penyu_hijau", (0.2, 0.55, 0.35))
    krem = material("penyu_krem", (0.9, 0.8, 0.6))
    gelap = material("mata_gelap", (0.1, 0.1, 0.1))
    root = root_empty("penyuci")
    # tempurung kubah + motif
    attach(root, add_ico("tempurung", 0.55, (0, 0, 0.42), kerang, subdiv=2, scale=(1.15, 1.0, 0.7)))
    for x in (-0.22, 0.0, 0.22):
        attach(root, add_ico("motif", 0.12, (x, 0, 0.72), hijau, subdiv=1, scale=(1, 1, 0.35)))
    # badan bawah krem
    attach(root, add_ico("badan", 0.45, (0, 0, 0.22), krem, subdiv=2, scale=(1.05, 0.9, 0.4)))
    # kepala
    attach(root, add_ico("kepala", 0.22, (0.72, 0, 0.4), krem, subdiv=2))
    add_eyes(root, (-0.09, 0.09), 0.47, gelap, r=0.04, offset=(0.78, 0))
    # sirip depan & belakang
    for y in (-0.5, 0.5):
        arah = 0.5 if y > 0 else -0.5
        attach(root, add_box("sirip_depan", (0.5, 0.2, 0.08), (0.15, y, 0.3), krem, rot=(0, arah, 0)))
        attach(root, add_box("sirip_belakang", (0.3, 0.18, 0.08), (-0.5, y * 0.9, 0.28), krem))


def build_monyet_kecil():
    """Monyet tahap 1: kecil lincah, ekor panjang, wajah krem."""
    clear_scene()
    coklat = material("monyet_coklat", (0.55, 0.38, 0.22))
    krem = material("monyet_muka", (0.9, 0.78, 0.62))
    gelap = material("mata_gelap", (0.1, 0.08, 0.06))
    root = root_empty("monyet_kecil")
    # badan + kepala + muka
    attach(root, add_ico("badan", 0.32, (0, 0, 0.75), coklat, subdiv=2, scale=(0.8, 0.7, 1.0)))
    attach(root, add_ico("kepala", 0.3, (0.28, 0, 1.28), coklat, subdiv=2))
    attach(root, add_ico("muka", 0.2, (0.42, 0, 1.25), krem, subdiv=2, scale=(0.7, 0.9, 0.9)))
    add_eyes(root, (-0.11, 0.11), 1.32, gelap, r=0.04, offset=(0.44, 0))
    # telinga
    for y in (-0.24, 0.24):
        attach(root, add_ico("telinga", 0.08, (0.22, y, 1.4), coklat, subdiv=1))
    # lengan & kaki tipis
    for y in (-0.26, 0.26):
        attach(root, add_cyl("lengan", 0.055, 0.55, (0.1, y, 0.5), coklat, rot=(0.5, 0, 0)))
    for y in (-0.16, 0.16):
        attach(root, add_cyl("kaki", 0.06, 0.45, (-0.08, y, 0.22), coklat))
    # ekor panjang melengkung ke atas
    attach(root, add_cyl("ekor", 0.04, 0.7, (-0.42, 0, 1.0), coklat, rot=(0, 1.1, 0)))
    attach(root, add_cyl("ekor_atas", 0.04, 0.4, (-0.7, 0, 1.3), coklat, rot=(0.8, 1.1, 0)))


def build_ayam_jantan():
    """Ayam tahap 1: jengger merah, ekor melengkung, kaki oranye."""
    clear_scene()
    merah = material("ayam_merah", (0.85, 0.2, 0.15))
    putih = material("ayam_putih", (0.95, 0.93, 0.88))
    oranye = material("ayam_oranye", (0.95, 0.55, 0.1))
    biru = material("ayam_ekor", (0.2, 0.25, 0.4))
    gelap = material("mata_gelap", (0.1, 0.08, 0.06))
    root = root_empty("ayam_jantan")
    # badan telur + leher + kepala
    attach(root, add_ico("badan", 0.42, (0, 0, 0.7), putih, subdiv=2, scale=(1.15, 0.8, 1.0)))
    attach(root, add_cyl("leher", 0.12, 0.4, (0.3, 0, 1.15), putih, rot=(0, 0.4, 0)))
    attach(root, add_ico("kepala", 0.17, (0.45, 0, 1.42), putih, subdiv=2))
    # jengger + paruh + pial
    attach(root, add_box("jengger", (0.28, 0.07, 0.14), (0.45, 0, 1.62), merah))
    attach(root, add_cone("paruh", 0.06, 0.16, (0.62, 0, 1.42), oranye, rot=(0, -1.57, 0)))
    for y in (-0.12, 0.12):
        attach(root, add_ico("mata", 0.03, (0.53, y, 1.47), gelap))
        attach(root, add_box("pial", (0.06, 0.04, 0.14), (0.5, y, 1.3), merah))
    # ekor bulu melengkung ke atas
    for i in range(3):
        warna = merah if i % 2 == 0 else biru
        attach(root, add_cone("ekor", 0.08, 0.55, (-0.55, (i - 1) * 0.12, 1.05 + i * 0.06), warna, rot=(0, 1.0 + i * 0.15, 0)))
    # kaki + cakar
    for y in (-0.12, 0.12):
        attach(root, add_cyl("kaki", 0.035, 0.4, (0.05, y, 0.3), oranye))
        attach(root, add_box("cakar", (0.16, 0.05, 0.04), (0.13, y, 0.09), oranye))


def build_rusa_muda():
    """Rusa tahap 1: anak rusa ramping, bintik krem, bakal tanduk."""
    clear_scene()
    coklat = material("rusa_coklat", (0.62, 0.42, 0.25))
    krem = material("rusa_bintik", (0.85, 0.72, 0.55))
    gelap = material("mata_gelap", (0.1, 0.08, 0.06))
    root = root_empty("rusa_muda")
    # badan ramping + bintik
    attach(root, add_box("badan", (0.95, 0.45, 0.5), (0, 0, 0.95), coklat))
    for x in (-0.28, 0.0, 0.28):
        attach(root, add_ico("bintik", 0.05, (x, 0.24, 1.0), krem, subdiv=1))
        attach(root, add_ico("bintik", 0.05, (x * 1.2, -0.24, 0.92), krem, subdiv=1))
    # leher + kepala + moncong
    attach(root, add_cyl("leher", 0.09, 0.45, (0.5, 0, 1.35), coklat, rot=(0, -0.4, 0)))
    attach(root, add_ico("kepala", 0.16, (0.68, 0, 1.62), coklat, subdiv=2, scale=(1.2, 0.9, 0.9)))
    attach(root, add_box("moncong", (0.14, 0.12, 0.1), (0.85, 0, 1.56), krem))
    add_eyes(root, (-0.08, 0.08), 1.68, gelap, r=0.03, offset=(0.68, 0))
    # bakal tanduk (tombol kecil)
    for y in (-0.15, 0.15):
        attach(root, add_ico("tanduk_kecil", 0.04, (0.6, y, 1.78), gelap))
    # kaki panjang tipis
    for x in (0.3, -0.3):
        for y in (-0.14, 0.14):
            attach(root, add_cyl("kaki", 0.045, 0.7, (x, y, 0.35), coklat))
    # ekor kecil krem
    attach(root, add_ico("ekor", 0.07, (-0.5, 0, 1.1), krem))


# ---------------------------------------------------------------- registry & CLI

BUILDERS = {
    "anak_rimau": build_anak_rimau,
    "orangkici": build_orangkici,
    "penyuci": build_penyuci,
    "monyet_kecil": build_monyet_kecil,
    "ayam_jantan": build_ayam_jantan,
    "rusa_muda": build_rusa_muda,
}


def export_model(path):
    """Ekspor seluruh objek scene ke glTF Binary."""
    folder = os.path.dirname(path)
    if folder:
        os.makedirs(folder, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True)


def parse_args():
    argv = sys.argv
    rest = argv[argv.index("--") + 1:] if "--" in argv else []
    p = argparse.ArgumentParser(description="NUSAMON asset builder")
    p.add_argument("--species", default="all",
                   help="id spesies dipisah koma, atau 'all' (default)")
    p.add_argument("--out", default=OUTPUT_DIR, help="folder output .glb")
    return p.parse_args(rest)


def main():
    args = parse_args()
    os.makedirs(args.out, exist_ok=True)
    if args.species.strip().lower() == "all":
        ids = list(BUILDERS)
    else:
        ids = [s.strip() for s in args.species.split(",") if s.strip()]
    for sid in ids:
        if sid not in BUILDERS:
            print("[NUSAMON] spesies tidak dikenal, dilewati:", sid)
            continue
        BUILDERS[sid]()
        out = os.path.join(args.out, sid + ".glb")
        export_model(out)
        print("[NUSAMON] OK:", out)


if __name__ == "__main__":
    main()
