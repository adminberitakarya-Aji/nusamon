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


# ---------------------------------------------------------------- spesies Fase 5
# Satu fungsi per line spesies (parameter `tahap`, 0-based). Registry di bawah
# memetakan tiap id tahapan (snake_case nama di data/nusamons.json — konsisten
# dengan NusamonData.id_model) ke pemanggilan builder.


def build_rimau(tahap):
    """Rimau tahap 2/3: kucing besar gagah; tahap akhir bersurai gelap."""
    clear_scene()
    oranye = material("rimau_oranye", (0.90, 0.45, 0.12))
    krem = material("rimau_krem", (0.95, 0.85, 0.68))
    gelap = material("rimau_gelap", (0.18, 0.11, 0.08))
    b = 1.5 if tahap >= 2 else 1.15
    root = root_empty("rimau_tahap%d" % tahap)
    z = 0.62 * b
    attach(root, add_box("badan", (1.1 * b, 0.62 * b, 0.58 * b), (0, 0, z), oranye))
    attach(root, add_box("kepala", (0.6 * b, 0.56 * b, 0.52 * b), (0.72 * b, 0, z * 1.4), oranye))
    attach(root, add_box("moncong", (0.22 * b, 0.3 * b, 0.2 * b), (1.02 * b, 0, z * 1.25), krem))
    for y in (-0.2, 0.2):
        attach(root, add_cone("telinga", 0.09 * b, 0.16 * b, (0.55 * b, y * b, z * 1.8), oranye))
    add_eyes(root, (-0.14 * b, 0.14 * b), z * 1.45, gelap, r=0.045 * b, offset=(0.9 * b, 0))
    for x in (0.38, -0.38):
        for y in (-0.22, 0.22):
            attach(root, add_box("kaki", (0.18 * b, 0.16 * b, 0.5 * b), (x * b, y * b, 0.25 * b), oranye))
    for i, x in enumerate((-0.35, -0.1, 0.15, 0.4)):
        attach(root, add_box("garis", (0.05, 0.66 * b, 0.5 * b), (x * b, 0, z + (i % 2) * 0.04), gelap))
    attach(root, add_cyl("ekor", 0.06 * b, 0.9 * b, (-0.75 * b, 0, z * 1.1), oranye, rot=(0, 1.2, 0)))
    attach(root, add_ico("ekor_ujung", 0.07 * b, (-1.15 * b, 0, z * 1.55), gelap))
    if tahap >= 2:
        for dy in (-0.3, 0.0, 0.3):
            for dx in (0.45, 0.72, 1.0):
                tinggi = z * 1.4 + (0.4 if dy == 0.0 else 0.25)
                attach(root, add_cone("surai", 0.1, 0.3, (0.72 * b + dx * 0.35, dy * b, tinggi), gelap, rot=(1.2, 0, 0)))


def build_orangutan(tahap):
    """Orangutan tahap 2/3: besar & berdiri tegak; tahap akhir berpipi pipih."""
    clear_scene()
    merah = material("orang_merah", (0.62, 0.32, 0.14))
    krem = material("orang_kulit", (0.85, 0.66, 0.5))
    gelap = material("mata_gelap", (0.12, 0.08, 0.06))
    b = 1.55 if tahap >= 2 else 1.2
    root = root_empty("orangutan_tahap%d" % tahap)
    attach(root, add_ico("badan", 0.5 * b, (0, 0, 1.0 * b), merah, subdiv=2, scale=(1, 0.8, 1.1)))
    attach(root, add_ico("perut", 0.34 * b, (0.14 * b, 0, 0.92 * b), krem, subdiv=2))
    attach(root, add_ico("kepala", 0.42 * b, (0.1 * b, 0, 1.85 * b), merah, subdiv=2))
    attach(root, add_ico("wajah", 0.3 * b, (0.32 * b, 0, 1.8 * b), krem, subdiv=2, scale=(0.6, 1, 0.8)))
    add_eyes(root, (-0.15 * b, 0.15 * b), 1.86 * b, gelap, r=0.05 * b, offset=(0.35 * b, 0))
    for y in (-0.45 * b, 0.45 * b):
        attach(root, add_cyl("lengan", 0.11 * b, 1.5 * b, (0.12 * b, y, 0.75 * b), merah, rot=(0.25, 0, 0)))
    for y in (-0.25 * b, 0.25 * b):
        attach(root, add_cyl("kaki", 0.13 * b, 0.5 * b, (-0.2 * b, y, 0.25 * b), merah))
    if tahap >= 2:
        for y in (-0.18 * b, 0.18 * b):
            attach(root, add_ico("pipi", 0.16 * b, (0.4 * b, y * 1.6, 1.68 * b), krem, subdiv=2))


def build_penyu(tahap):
    """Penyu tahap 2/3: tempurung megah; tahap akhir raksasa samudra bersirip ekstra."""
    clear_scene()
    kerang = material("penyu_kerang", (0.25, 0.7, 0.5))
    hijau = material("penyu_hijau", (0.2, 0.55, 0.35))
    krem = material("penyu_krem", (0.9, 0.8, 0.6))
    gelap = material("mata_gelap", (0.1, 0.1, 0.1))
    b = 1.6 if tahap >= 2 else 1.2
    root = root_empty("penyu_tahap%d" % tahap)
    attach(root, add_ico("tempurung", 0.55 * b, (0, 0, 0.42 * b), kerang, subdiv=2, scale=(1.15, 1.0, 0.7)))
    for x in (-0.22, 0.0, 0.22):
        attach(root, add_ico("motif", 0.12 * b, (x * b, 0, 0.74 * b), hijau, subdiv=1, scale=(1, 1, 0.35)))
    attach(root, add_ico("badan", 0.45 * b, (0, 0, 0.22 * b), krem, subdiv=2, scale=(1.05, 0.9, 0.4)))
    attach(root, add_ico("kepala", 0.22 * b, (0.72 * b, 0, 0.4 * b), krem, subdiv=2))
    add_eyes(root, (-0.09 * b, 0.09 * b), 0.47 * b, gelap, r=0.04 * b, offset=(0.78 * b, 0))
    for y in (-0.5, 0.5):
        arah = 0.5 if y > 0 else -0.5
        attach(root, add_box("sirip_depan", (0.5 * b, 0.2 * b, 0.08 * b), (0.15 * b, y * b, 0.3 * b), krem, rot=(0, arah, 0)))
        attach(root, add_box("sirip_belakang", (0.3 * b, 0.18 * b, 0.08 * b), (-0.5 * b, y * 0.9 * b, 0.28 * b), krem))
    if tahap >= 2:
        for x in (-0.35, 0.0, 0.35):
            attach(root, add_cone("duri", 0.07 * b, 0.25 * b, (x * b, 0, 0.86 * b), hijau))
        for y in (-0.7, 0.7):
            attach(root, add_box("sirip_tengah", (0.4 * b, 0.16 * b, 0.07 * b), (-0.2 * b, y * b, 0.34 * b), krem, rot=(0, 0.9, 0)))


def build_elang_garuda():
    """Elang Garuda (legendary): burung emas berjambul, sayap lebar, cakar kuat."""
    clear_scene()
    coklat = material("elang_coklat", (0.42, 0.26, 0.12))
    emas = material("elang_emas", (0.95, 0.75, 0.25))
    putih = material("elang_putih", (0.95, 0.93, 0.85))
    gelap = material("mata_gelap", (0.08, 0.06, 0.04))
    root = root_empty("elang_garuda")
    attach(root, add_ico("badan", 0.45, (0, 0, 0.95), coklat, subdiv=2, scale=(1.25, 0.75, 1.0)))
    attach(root, add_ico("kepala", 0.24, (0.5, 0, 1.45), emas, subdiv=2))
    attach(root, add_cone("paruh", 0.07, 0.22, (0.72, 0, 1.42), gelap, rot=(0, -1.57, 0)))
    add_eyes(root, (-0.1, 0.1), 1.52, gelap, r=0.04, offset=(0.6, 0))
    for i in range(3):
        attach(root, add_cone("jambul", 0.05, 0.3, (0.42 - i * 0.1, 0, 1.72 + i * 0.08), emas, rot=(0, 0.9, 0)))
    for y in (-1, 1):
        attach(root, add_box("sayap", (0.5, 1.1, 0.08), (0.0, y * 0.75, 1.15), coklat, rot=(0, y * 0.35, 0)))
        attach(root, add_box("bulu_sayap", (0.4, 0.8, 0.06), (-0.2, y * 1.15, 1.05), coklat, rot=(0, y * 0.5, 0)))
    attach(root, add_ico("ekor", 0.22, (-0.62, 0, 0.95), putih, subdiv=1, scale=(1.4, 0.9, 0.4)))
    for y in (-0.15, 0.15):
        attach(root, add_cyl("kaki", 0.05, 0.45, (0.1, y, 0.35), emas))
        attach(root, add_cone("cakar", 0.06, 0.14, (0.22, y, 0.1), gelap, rot=(0, 0, 1.57)))


def build_cenderawasih_agung():
    """Cenderawasih Agung (legendary): ekor kawat menjuntai, plume kuning."""
    clear_scene()
    merah = material("cendra_merah", (0.75, 0.2, 0.3))
    coklat = material("cendra_coklat", (0.5, 0.3, 0.15))
    kuning = material("cendra_kuning", (0.95, 0.8, 0.3))
    putih = material("cendra_putih", (0.95, 0.95, 0.9))
    gelap = material("mata_gelap", (0.08, 0.06, 0.04))
    root = root_empty("cenderawasih_agung")
    attach(root, add_ico("badan", 0.34, (0, 0, 1.0), coklat, subdiv=2, scale=(1.2, 0.7, 0.95)))
    attach(root, add_ico("kepala", 0.18, (0.4, 0, 1.4), coklat, subdiv=2))
    attach(root, add_cone("paruh", 0.05, 0.2, (0.58, 0, 1.38), gelap, rot=(0, -1.57, 0)))
    add_eyes(root, (-0.07, 0.07), 1.45, gelap, r=0.03, offset=(0.5, 0))
    for dy in (-0.08, 0.0, 0.08):
        attach(root, add_cone("plume", 0.04, 0.28, (0.36, dy, 1.62), kuning, rot=(0.6, 0, 0)))
    for y in (-1, 1):
        attach(root, add_box("sayap", (0.4, 0.8, 0.07), (0, y * 0.5, 1.15), merah, rot=(0, y * 0.4, 0)))
    for i in range(4):
        attach(root, add_cyl("ekor_kawat", 0.015, 0.9 + i * 0.12, (-0.5 - i * 0.06, (i - 1.5) * 0.1, 0.75 - i * 0.12), putih, rot=(0, 1.35 + i * 0.04, 0)))
        attach(root, add_ico("ujung_kawat", 0.035, (-0.95 - i * 0.09, (i - 1.5) * 0.1, 0.45 - i * 0.16), merah))
    for y in (-0.1, 0.1):
        attach(root, add_cyl("kaki", 0.03, 0.4, (0.05, y, 0.35), kuning))


def build_paus_samudra():
    """Paus Samudra (legendary): raksasa laut dalam bersirip dan ekor besar."""
    clear_scene()
    biru = material("paus_biru", (0.16, 0.3, 0.5))
    muda = material("paus_perut", (0.65, 0.75, 0.85))
    gelap = material("mata_gelap", (0.05, 0.07, 0.1))
    root = root_empty("paus_samudra")
    attach(root, add_ico("badan", 0.85, (0, 0, 0.85), biru, subdiv=2, scale=(2.1, 0.9, 0.85)))
    attach(root, add_ico("perut", 0.6, (0.1, 0, 0.45), muda, subdiv=2, scale=(1.8, 0.7, 0.5)))
    attach(root, add_ico("kepala", 0.55, (1.35, 0, 0.85), biru, subdiv=2, scale=(1.1, 0.85, 0.7)))
    add_eyes(root, (-0.3, 0.3), 0.95, gelap, r=0.06, offset=(1.35, 0))
    for y in (-0.6, 0.6):
        attach(root, add_box("sirip_dada", (0.7, 0.35, 0.1), (0.5, y, 0.55), biru, rot=(0, 0.5, 0)))
    attach(root, add_cone("sirip_punggung", 0.2, 0.35, (-0.3, 0, 1.6), biru))
    for y in (-1, 1):
        attach(root, add_box("ekor", (0.5, 0.55, 0.09), (-2.05, y * 0.35, 0.95), biru, rot=(0, 0.7, y * 0.35)))
    attach(root, add_cyl("tangkai_ekor", 0.18, 0.9, (-1.65, 0, 0.9), biru, rot=(0, 1.57, 0)))


def build_biawak(tahap):
    """Biawak→Komodo→Komodo Raja: kadal besar; tahap akhir bersayap naga & tanduk."""
    clear_scene()
    abu = material("biawak_abu", (0.35, 0.4, 0.3))
    krem = material("biawak_perut", (0.7, 0.68, 0.55))
    gelap = material("mata_gelap", (0.08, 0.07, 0.05))
    b = 1.6 if tahap >= 2 else (1.2 if tahap == 1 else 0.8)
    root = root_empty("biawak_tahap%d" % tahap)
    attach(root, add_box("badan", (1.2 * b, 0.5 * b, 0.42 * b), (0, 0, 0.5 * b), abu))
    attach(root, add_box("perut", (1.0 * b, 0.3 * b, 0.2 * b), (0, 0, 0.3 * b), krem))
    attach(root, add_box("kepala", (0.5 * b, 0.34 * b, 0.28 * b), (0.8 * b, 0, 0.62 * b), abu))
    attach(root, add_box("moncong", (0.3 * b, 0.22 * b, 0.16 * b), (1.15 * b, 0, 0.55 * b), abu))
    add_eyes(root, (-0.1 * b, 0.1 * b), 0.7 * b, gelap, r=0.04 * b, offset=(0.9 * b, 0))
    for x in (0.4, -0.4):
        for y in (-0.18, 0.18):
            attach(root, add_box("kaki", (0.14 * b, 0.12 * b, 0.4 * b), (x * b, y * b, 0.2 * b), abu))
    # ekor panjang menyapu belakang
    for i in range(3):
        attach(root, add_cyl("ekor", 0.09 * b * (1.0 - i * 0.25), 0.6 * b, (-0.8 * b - i * 0.45 * b, 0, 0.45 * b), abu, rot=(0, 1.57, 0)))
    # punggung bergerigi
    for x in (-0.4, -0.1, 0.2):
        attach(root, add_cone("gerigi", 0.05 * b, 0.14 * b, (x * b, 0, 0.75 * b), krem))
    if tahap >= 2:
        # sayap naga + tanduk
        for y in (-1, 1):
            attach(root, add_box("sayap", (0.55, 0.9, 0.06), (-0.1, y * 0.62, 0.9), abu, rot=(0, y * 0.45, 0)))
        for y in (-0.12, 0.12):
            attach(root, add_cone("tanduk", 0.05, 0.24, (0.66 * b, y, 0.82 * b), krem))


def build_gajah(tahap):
    """Gajah Sapi→Gajah Sumatra→Gajah Raksasa: belalai & gading memanjang."""
    clear_scene()
    abu = material("gajah_abu", (0.55, 0.55, 0.58))
    gelap = material("mata_gelap", (0.08, 0.08, 0.08))
    gading = material("gajah_gading", (0.95, 0.93, 0.85))
    b = 1.7 if tahap >= 2 else (1.25 if tahap == 1 else 0.85)
    root = root_empty("gajah_tahap%d" % tahap)
    attach(root, add_box("badan", (1.5 * b, 0.95 * b, 1.0 * b), (0, 0, 1.1 * b), abu))
    attach(root, add_ico("kepala", 0.45 * b, (0.95 * b, 0, 1.5 * b), abu, subdiv=2))
    add_eyes(root, (-0.2 * b, 0.2 * b), 1.55 * b, gelap, r=0.045 * b, offset=(1.15 * b, 0))
    # belalai 3 ruas menurun
    for i in range(3):
        attach(root, add_cyl("belalai", 0.11 * b - i * 0.015, 0.42 * b, (1.32 * b + i * 0.14 * b, 0, 1.15 * b - i * 0.33 * b), abu, rot=(0.5 + i * 0.25, 0, 0)))
    # telinga lebar
    for y in (-1, 1):
        attach(root, add_box("telinga", (0.45 * b, 0.08 * b, 0.6 * b), (0.85 * b, y * 0.5 * b, 1.55 * b), abu, rot=(0, y * 0.25, 0)))
    # gading makin panjang tiap tahap
    panjang = 0.2 * (tahap + 1)
    for y in (-0.18, 0.18):
        attach(root, add_cone("gading", 0.05 * b, panjang * b, (1.25 * b, y, 1.05 * b), gading, rot=(2.4, 0, 0)))
    for x in (0.5, -0.5):
        for y in (-0.3, 0.3):
            attach(root, add_cyl("kaki", 0.16 * b, 1.1 * b, (x * b, y * b, 0.55 * b), abu))


def build_badak(tahap):
    """Badak Muda→Sumatra→Baja: tanduk tumbuh; tahap akhir berzirah baja."""
    clear_scene()
    abu = material("badak_abu", (0.5, 0.48, 0.45))
    baja = material("badak_baja", (0.62, 0.64, 0.7))
    tanduk_m = material("badak_tanduk", (0.9, 0.87, 0.78))
    gelap = material("mata_gelap", (0.08, 0.08, 0.08))
    b = 1.7 if tahap >= 2 else (1.25 if tahap == 1 else 0.85)
    root = root_empty("badak_tahap%d" % tahap)
    kulit = baja if tahap >= 2 else abu
    attach(root, add_box("badan", (1.6 * b, 0.9 * b, 0.95 * b), (0, 0, 1.05 * b), kulit))
    attach(root, add_box("kepala", (0.55 * b, 0.4 * b, 0.5 * b), (1.0 * b, 0, 1.15 * b), kulit))
    attach(root, add_box("moncong", (0.25 * b, 0.3 * b, 0.3 * b), (1.35 * b, 0, 1.0 * b), kulit))
    add_eyes(root, (-0.12 * b, 0.12 * b), 1.25 * b, gelap, r=0.04 * b, offset=(1.1 * b, 0))
    # tanduk utama + tanduk kedua (tahap 2)
    attach(root, add_cone("tanduk", 0.09 * b, (0.3 + 0.25 * tahap) * b, (1.2 * b, 0, 1.55 * b), tanduk_m))
    if tahap >= 1:
        attach(root, add_cone("tanduk_kedua", 0.06 * b, 0.2 * b, (1.42 * b, 0, 1.4 * b), tanduk_m))
    # lempeng zirah tahap akhir
    if tahap >= 2:
        for i, x in enumerate((-0.55, -0.2, 0.15, 0.5)):
            attach(root, add_box("zirah", (0.24, 0.96, 0.1), (x, 0, 1.55), baja, rot=(0, 0.1 * i, 0)))
    for x in (0.55, -0.55):
        for y in (-0.3, 0.3):
            attach(root, add_cyl("kaki", 0.15 * b, 1.05 * b, (x * b, y * b, 0.52 * b), kulit))
    attach(root, add_cyl("ekor", 0.05 * b, 0.6 * b, (-0.85 * b, 0, 1.1 * b), kulit, rot=(0, 1.2, 0)))


def build_hiu(tahap):
    """Hiu Kecil→Raksasa: ikan fusiform bersirip punggung tajam."""
    clear_scene()
    biru = material("hiu_biru", (0.35, 0.45, 0.55))
    putih = material("hiu_perut", (0.85, 0.88, 0.9))
    gelap = material("mata_gelap", (0.05, 0.06, 0.08))
    b = 1.5 if tahap >= 1 else 0.85
    root = root_empty("hiu_tahap%d" % tahap)
    attach(root, add_ico("badan", 0.5 * b, (0, 0, 0.6 * b), biru, subdiv=2, scale=(2.0, 0.7, 0.7)))
    attach(root, add_ico("perut", 0.38 * b, (0.05, 0, 0.42 * b), putih, subdiv=2, scale=(1.7, 0.55, 0.4)))
    attach(root, add_cone("moncong", 0.3 * b, 0.5 * b, (0.95 * b, 0, 0.6 * b), biru, rot=(0, 1.57, 0)))
    add_eyes(root, (-0.2 * b, 0.2 * b), 0.68 * b, gelap, r=0.05 * b, offset=(0.8 * b, 0))
    attach(root, add_cone("sirip_punggung", 0.18 * b, 0.5 * b, (-0.1, 0, 1.15 * b), biru))
    for y in (-0.55, 0.55):
        attach(root, add_box("sirip_samping", (0.5 * b, 0.3 * b, 0.06 * b), (0.3 * b, y * b, 0.4 * b), biru, rot=(0, 0.5, 0)))
    attach(root, add_box("ekor", (0.45 * b, 0.5 * b, 0.08 * b), (-1.25 * b, 0, 0.75 * b), biru, rot=(0, 0.9, 0)))
    attach(root, add_cyl("tangkai_ekor", 0.1 * b, 0.5 * b, (-0.95 * b, 0, 0.65 * b), biru, rot=(0, 1.57, 0)))


def build_buaya(tahap):
    """Buaya Kecil→Raksasa: tubuh rendah panjang, moncong, ekor kuat."""
    clear_scene()
    hijau = material("buaya_hijau", (0.3, 0.45, 0.2))
    krem = material("buaya_perut", (0.75, 0.72, 0.5))
    gelap = material("mata_gelap", (0.06, 0.07, 0.04))
    b = 1.55 if tahap >= 1 else 0.85
    root = root_empty("buaya_tahap%d" % tahap)
    attach(root, add_box("badan", (1.3 * b, 0.55 * b, 0.35 * b), (0, 0, 0.35 * b), hijau))
    attach(root, add_box("perut", (1.1 * b, 0.35 * b, 0.15 * b), (0, 0, 0.18 * b), krem))
    attach(root, add_box("kepala", (0.45 * b, 0.35 * b, 0.25 * b), (0.85 * b, 0, 0.42 * b), hijau))
    attach(root, add_box("moncong", (0.5 * b, 0.22 * b, 0.14 * b), (1.3 * b, 0, 0.35 * b), hijau))
    add_eyes(root, (-0.12 * b, 0.12 * b), 0.52 * b, gelap, r=0.04 * b, offset=(0.9 * b, 0))
    for x in (0.45, -0.45):
        for y in (-0.2, 0.2):
            attach(root, add_box("kaki", (0.16 * b, 0.1 * b, 0.28 * b), (x * b, y * b, 0.14 * b), hijau))
    for i in range(4):
        attach(root, add_cyl("ekor", 0.12 * b * (1.0 - i * 0.2), 0.55 * b, (-0.85 * b - i * 0.45 * b, 0, 0.32 * b), hijau, rot=(0, 1.57, 0)))
    for x in (-0.35, -0.05, 0.25):
        attach(root, add_cone("gerigi", 0.04 * b, 0.12 * b, (x * b, 0, 0.55 * b), krem))


def build_banteng(tahap):
    """Banteng Muda→Murba: sapi liar bertanduk dengan punggung putih."""
    clear_scene()
    coklat = material("banteng_coklat", (0.4, 0.22, 0.12))
    putih = material("banteng_putih", (0.92, 0.9, 0.85))
    tanduk_m = material("banteng_tanduk", (0.85, 0.8, 0.65))
    gelap = material("mata_gelap", (0.07, 0.06, 0.05))
    b = 1.45 if tahap >= 1 else 0.85
    root = root_empty("banteng_tahap%d" % tahap)
    attach(root, add_box("badan", (1.3 * b, 0.7 * b, 0.8 * b), (0, 0, 0.95 * b), coklat))
    attach(root, add_box("punggung", (0.7 * b, 0.72 * b, 0.4 * b), (-0.3 * b, 0, 1.2 * b), putih))
    attach(root, add_ico("kepala", 0.3 * b, (0.8 * b, 0, 1.25 * b), coklat, subdiv=2))
    add_eyes(root, (-0.12 * b, 0.12 * b), 1.3 * b, gelap, r=0.04 * b, offset=(0.95 * b, 0))
    for y in (-0.15 * b, 0.15 * b):
        attach(root, add_cone("tanduk", 0.05 * b, 0.35 * b, (0.8 * b, y, 1.5 * b), tanduk_m, rot=(0, y * -0.8, 0)))
    for x in (0.45, -0.45):
        for y in (-0.25, 0.25):
            attach(root, add_cyl("kaki", 0.09 * b, 1.0 * b, (x * b, y * b, 0.5 * b), coklat))
    attach(root, add_cyl("ekor", 0.04 * b, 0.7 * b, (-0.75 * b, 0, 1.0 * b), coklat, rot=(0, 1.3, 0)))


def build_babirusa(tahap):
    """Babirusa Muda→Raksasa: babi rusa dengan taring melengkung ke atas."""
    clear_scene()
    coklat = material("babirusa_coklat", (0.6, 0.42, 0.28))
    krem = material("babirusa_krem", (0.85, 0.75, 0.6))
    taring_m = material("babirusa_taring", (0.92, 0.88, 0.75))
    gelap = material("mata_gelap", (0.07, 0.06, 0.05))
    b = 1.4 if tahap >= 1 else 0.8
    root = root_empty("babirusa_tahap%d" % tahap)
    attach(root, add_ico("badan", 0.45 * b, (0, 0, 0.6 * b), coklat, subdiv=2, scale=(1.6, 0.8, 0.9)))
    attach(root, add_ico("kepala", 0.26 * b, (0.65 * b, 0, 0.8 * b), coklat, subdiv=2))
    attach(root, add_box("moncong", (0.2 * b, 0.16 * b, 0.14 * b), (0.9 * b, 0, 0.7 * b), krem))
    add_eyes(root, (-0.09 * b, 0.09 * b), 0.85 * b, gelap, r=0.035 * b, offset=(0.78 * b, 0))
    for y in (-0.08 * b, 0.08 * b):
        attach(root, add_cone("taring", 0.03 * b, 0.4 * b, (0.85 * b, y, 0.9 * b), taring_m, rot=(0.6, 0, 0)))
    for x in (-0.2, 0.1):
        attach(root, add_cone("bulu_punggung", 0.04 * b, 0.15 * b, (x * b, 0, 0.95 * b), krem))
    for x in (0.3, -0.3):
        for y in (-0.15, 0.15):
            attach(root, add_cyl("kaki", 0.05 * b, 0.45 * b, (x * b, y * b, 0.22 * b), coklat))


def build_beruang(tahap):
    """Beruang Muda→Madu: beruang hitam; dewasa berlambang madu keemasan."""
    clear_scene()
    hitam = material("beruang_hitam", (0.22, 0.16, 0.12))
    emas = material("beruang_madu", (0.95, 0.75, 0.3))
    moncong_m = material("beruang_moncong", (0.75, 0.65, 0.5))
    gelap = material("mata_gelap", (0.05, 0.04, 0.03))
    b = 1.5 if tahap >= 1 else 0.9
    root = root_empty("beruang_tahap%d" % tahap)
    attach(root, add_ico("badan", 0.5 * b, (0, 0, 0.7 * b), hitam, subdiv=2, scale=(1.3, 0.85, 1.0)))
    attach(root, add_ico("kepala", 0.3 * b, (0.6 * b, 0, 1.05 * b), hitam, subdiv=2))
    attach(root, add_ico("moncong", 0.14 * b, (0.85 * b, 0, 0.95 * b), moncong_m, subdiv=2))
    add_eyes(root, (-0.1 * b, 0.1 * b), 1.12 * b, gelap, r=0.04 * b, offset=(0.78 * b, 0))
    for y in (-0.18 * b, 0.18 * b):
        attach(root, add_ico("telinga", 0.08 * b, (0.5 * b, y, 1.3 * b), hitam, subdiv=1))
    if tahap >= 1:
        attach(root, add_ico("lambang_madu", 0.14 * b, (0.5 * b, 0, 0.85 * b), emas, subdiv=2, scale=(0.5, 0.9, 1.0)))
    for x in (0.35, -0.35):
        for y in (-0.25, 0.25):
            attach(root, add_cyl("kaki", 0.11 * b, 0.5 * b, (x * b, y * b, 0.25 * b), hitam))


def build_rangkong(tahap):
    """Rangkong Muda→Agung: burung bertanduk (casque) paruh besar."""
    clear_scene()
    hitam = material("rangkong_hitam", (0.2, 0.18, 0.2))
    putih = material("rangkong_putih", (0.92, 0.9, 0.85))
    kuning = material("rangkong_kuning", (0.95, 0.78, 0.25))
    gelap = material("mata_gelap", (0.06, 0.05, 0.04))
    b = 1.5 if tahap >= 1 else 0.9
    root = root_empty("rangkong_tahap%d" % tahap)
    attach(root, add_ico("badan", 0.35 * b, (0, 0, 0.95 * b), hitam, subdiv=2, scale=(1.2, 0.7, 0.95)))
    attach(root, add_ico("kepala", 0.18 * b, (0.42 * b, 0, 1.35 * b), hitam, subdiv=2))
    # paruh besar + casque (tanduk paruh) khas rangkong
    attach(root, add_cone("paruh", 0.07 * b, 0.45 * b, (0.68 * b, 0, 1.3 * b), kuning, rot=(0, -1.57, 0)))
    attach(root, add_ico("casque", 0.09 * b, (0.5 * b, 0, 1.52 * b), kuning, subdiv=2, scale=(1.4, 0.8, 0.8)))
    add_eyes(root, (-0.07 * b, 0.07 * b), 1.4 * b, gelap, r=0.03 * b, offset=(0.52 * b, 0))
    for y in (-1, 1):
        attach(root, add_box("sayap", (0.4 * b, 0.7 * b, 0.06 * b), (0, y * 0.45 * b, 1.05 * b), hitam, rot=(0, y * 0.4, 0)))
    attach(root, add_box("ekor", (0.6 * b, 0.3 * b, 0.06 * b), (-0.6 * b, 0, 0.95 * b), putih, rot=(0, 0.5, 0)))
    for y in (-0.08 * b, 0.08 * b):
        attach(root, add_cyl("kaki", 0.03 * b, 0.45 * b, (0.05, y, 0.4 * b), kuning))


def build_merak(tahap):
    """Merak Muda→Agung: dewasa mengembangkan ekor kipas biru kehijauan."""
    clear_scene()
    biru = material("merak_biru", (0.15, 0.3, 0.7))
    hijau = material("merak_hijau", (0.2, 0.6, 0.4))
    emas = material("merak_mata", (0.95, 0.8, 0.3))
    gelap = material("mata_gelap", (0.06, 0.05, 0.04))
    b = 1.4 if tahap >= 1 else 0.85
    root = root_empty("merak_tahap%d" % tahap)
    attach(root, add_ico("badan", 0.3 * b, (0, 0, 0.75 * b), biru, subdiv=2, scale=(1.15, 0.7, 1.0)))
    attach(root, add_cyl("leher", 0.07 * b, 0.4 * b, (0.22 * b, 0, 1.1 * b), biru, rot=(0, 0.3, 0)))
    attach(root, add_ico("kepala", 0.13 * b, (0.32 * b, 0, 1.35 * b), biru, subdiv=2))
    add_eyes(root, (-0.05 * b, 0.05 * b), 1.38 * b, gelap, r=0.025 * b, offset=(0.4 * b, 0))
    for y in (-1, 1):
        attach(root, add_box("sayap", (0.35 * b, 0.55 * b, 0.05 * b), (-0.05, y * 0.35 * b, 0.8 * b), hijau, rot=(0, y * 0.4, 0)))
    for y in (-0.07 * b, 0.07 * b):
        attach(root, add_cyl("kaki", 0.025 * b, 0.4 * b, (0.05, y, 0.2 * b), emas))
    if tahap >= 1:
        # kipas ekor: deretan bulu ber"mata" emas
        for i in range(7):
            ang = (i - 3) * 0.35
            attach(root, add_cone("bulu_ekor", 0.09 * b, 1.1 * b, (-0.5 * b + i * 0.06, (i - 3) * 0.35 * b, 1.0 * b + 0.35 * b * (1 - abs(i - 3) * 0.15)), hijau, rot=(1.2, ang * 0.3, 0)))
            attach(root, add_ico("mata_bulu", 0.05 * b, (-0.95 * b + i * 0.1, (i - 3) * 0.42 * b, 1.3 * b), emas, subdiv=1))


def build_lumba(tahap):
    """Lumba Kecil→Petir: lumba-lumba gesit; dewasa bermotif petir kuning."""
    clear_scene()
    biru = material("lumba_biru", (0.25, 0.45, 0.7))
    muda = material("lumba_perut", (0.8, 0.87, 0.92))
    kuning = material("lumba_petir", (0.98, 0.85, 0.25))
    gelap = material("mata_gelap", (0.05, 0.05, 0.07))
    b = 1.45 if tahap >= 1 else 0.85
    root = root_empty("lumba_tahap%d" % tahap)
    attach(root, add_ico("badan", 0.4 * b, (0, 0, 0.65 * b), biru, subdiv=2, scale=(2.1, 0.6, 0.7)))
    attach(root, add_ico("perut", 0.3 * b, (0.05, 0, 0.48 * b), muda, subdiv=2, scale=(1.8, 0.5, 0.4)))
    attach(root, add_cone("rostrum", 0.09 * b, 0.35 * b, (0.85 * b, 0, 0.65 * b), biru, rot=(0, 1.57, 0)))
    add_eyes(root, (-0.18 * b, 0.18 * b), 0.72 * b, gelap, r=0.04 * b, offset=(0.7 * b, 0))
    attach(root, add_cone("dorsal", 0.12 * b, 0.3 * b, (-0.1, 0, 1.0 * b), biru))
    for y in (-0.4, 0.4):
        attach(root, add_box("sirip_samping", (0.45 * b, 0.22 * b, 0.05 * b), (0.25 * b, y * b, 0.45 * b), biru, rot=(0, 0.6, 0)))
    attach(root, add_box("ekor", (0.4 * b, 0.45 * b, 0.07 * b), (-1.1 * b, 0, 0.7 * b), biru, rot=(0, 0.8, 0)))
    if tahap >= 1:
        for i, x in enumerate((-0.3, 0.0, 0.3)):
            attach(root, add_box("petir", (0.2 * b, 0.06 * b, 0.05 * b), (x * b, 0.28 * b, 0.55 * b - i * 0.05), kuning, rot=(0, 0.5, 0.3)))


def build_arwana(tahap):
    """Arwana Kecil→Naga: ikan tubuh panjang; dewasa berkumis & duri punggung."""
    clear_scene()
    emas = material("arwana_emas", (0.9, 0.7, 0.25))
    perak = material("arwana_perut", (0.9, 0.88, 0.8))
    merah = material("arwana_sirip", (0.8, 0.3, 0.2))
    gelap = material("mata_gelap", (0.06, 0.05, 0.04))
    b = 1.5 if tahap >= 1 else 0.85
    root = root_empty("arwana_tahap%d" % tahap)
    attach(root, add_ico("badan", 0.3 * b, (0, 0, 0.7 * b), emas, subdiv=2, scale=(2.6, 0.6, 0.8)))
    attach(root, add_ico("perut", 0.22 * b, (0, 0, 0.55 * b), perak, subdiv=2, scale=(2.2, 0.45, 0.4)))
    attach(root, add_ico("kepala", 0.2 * b, (0.75 * b, 0, 0.75 * b), emas, subdiv=2, scale=(1.2, 0.8, 0.7)))
    add_eyes(root, (-0.12 * b, 0.12 * b), 0.8 * b, gelap, r=0.035 * b, offset=(0.82 * b, 0))
    if tahap >= 1:
        for y in (-0.08 * b, 0.08 * b):
            attach(root, add_cyl("kumis", 0.012 * b, 0.3 * b, (1.0 * b, y, 0.72 * b), merah, rot=(1.4, 0, 0)))
        for x in (-0.5, -0.25, 0.0, 0.25, 0.5):
            attach(root, add_cone("duri_punggung", 0.03 * b, 0.18 * b, (x * b, 0, 1.0 * b), merah))
    attach(root, add_box("ekor", (0.5 * b, 0.4 * b, 0.06 * b), (-0.85 * b, 0, 0.72 * b), merah, rot=(0, 0.6, 0)))
    for y in (-0.3, 0.3):
        attach(root, add_box("sirip", (0.35 * b, 0.2 * b, 0.05 * b), (0.1, y * b, 0.5 * b), merah, rot=(0, 0.4, 0)))


def build_gurita(tahap):
    """Gurita Kecil→Raksasa: kepala kubah + 8 lengan melengkung."""
    clear_scene()
    ungu = material("gurita_ungu", (0.5, 0.3, 0.6))
    muda = material("gurita_perut", (0.75, 0.65, 0.8))
    gelap = material("mata_gelap", (0.06, 0.05, 0.08))
    b = 1.5 if tahap >= 1 else 0.85
    root = root_empty("gurita_tahap%d" % tahap)
    attach(root, add_ico("kepala", 0.45 * b, (0, 0, 0.95 * b), ungu, subdiv=2, scale=(1.0, 0.85, 1.1)))
    add_eyes(root, (-0.2 * b, 0.2 * b), 0.7 * b, gelap, r=0.07 * b, offset=(0.3 * b, 0))
    for i, dy in enumerate((-0.3, -0.1, 0.1, 0.3)):
        for sx in (-1, 1):
            panjang = 0.7 * b - abs(dy) * 0.3 * b
            attach(root, add_cyl("lengan", 0.09 * b - abs(dy) * 0.05, panjang, (0.3 * b, dy * b, 0.4 * b - i * 0.06), ungu, rot=(1.2, 0, sx * 0.15)))
            attach(root, add_ico("ujung_lengan", 0.06 * b, (0.62 * b, dy * 1.1 * b, 0.12 * b), muda, subdiv=1))
    if tahap >= 1:
        for x, y in ((-0.2, 0.25), (0.1, -0.3), (0.35, 0.1), (-0.05, 0.4)):
            attach(root, add_ico("bintik", 0.07 * b, (x * b, y * b, 0.85 * b), muda, subdiv=1, scale=(1, 1, 0.4)))


def build_kakatua(tahap):
    """Kakatua Muda→Raja: jambul melengkung; dewasa berjambul kuning megah."""
    clear_scene()
    putih = material("kakatua_putih", (0.95, 0.94, 0.9))
    kuning = material("kakatua_jambul", (0.98, 0.85, 0.3))
    abu = material("kakatua_paruh", (0.5, 0.45, 0.4))
    gelap = material("mata_gelap", (0.06, 0.05, 0.04))
    b = 1.4 if tahap >= 1 else 0.85
    root = root_empty("kakatua_tahap%d" % tahap)
    attach(root, add_ico("badan", 0.28 * b, (0, 0, 0.8 * b), putih, subdiv=2, scale=(1.2, 0.7, 1.0)))
    attach(root, add_ico("kepala", 0.17 * b, (0.25 * b, 0, 1.3 * b), putih, subdiv=2))
    attach(root, add_cone("paruh", 0.06 * b, 0.25 * b, (0.45 * b, 0, 1.25 * b), abu, rot=(0, -1.3, 0)))
    add_eyes(root, (-0.06 * b, 0.06 * b), 1.33 * b, gelap, r=0.028 * b, offset=(0.35 * b, 0))
    for i in range(4):
        warna = kuning if tahap >= 1 else putih
        attach(root, add_cone("jambul", 0.03 * b, (0.2 + 0.1 * (i % 2)) * b, (0.2 * b - i * 0.07 * b, 0, (1.45 + i * 0.08) * b), warna, rot=(0.5 + i * 0.15, 0, 0)))
    for y in (-1, 1):
        attach(root, add_box("sayap", (0.3 * b, 0.5 * b, 0.05 * b), (-0.05, y * 0.35 * b, 0.85 * b), putih, rot=(0, y * 0.3, 0)))
    attach(root, add_box("ekor", (0.45 * b, 0.25 * b, 0.05 * b), (-0.45 * b, 0, 0.7 * b), kuning if tahap >= 1 else putih, rot=(0, 0.7, 0)))
    for y in (-0.06 * b, 0.06 * b):
        attach(root, add_cyl("kaki", 0.02 * b, 0.3 * b, (0.05, y, 0.15 * b), abu))


def build_ular(tahap):
    """Ular Kecil→Raksasa: tubuh ruas membelok; dewasa berkepala lebar."""
    clear_scene()
    hijau = material("ular_hijau", (0.35, 0.55, 0.25))
    krem = material("ular_perut", (0.8, 0.78, 0.6))
    gelap = material("mata_gelap", (0.06, 0.07, 0.04))
    merah = material("ular_lidah", (0.85, 0.2, 0.2))
    b = 1.5 if tahap >= 1 else 0.85
    root = root_empty("ular_tahap%d" % tahap)
    for i in range(6):
        x = 0.4 * b - i * 0.38 * b
        z = 0.4 * b + (0.12 * b if i % 2 == 0 else 0.0)
        yy = (i % 3 - 1) * 0.12 * b
        attach(root, add_ico("ruas", 0.17 * b * (1.0 - i * 0.08), (x, yy, z), hijau, subdiv=2))
        attach(root, add_ico("sisik_perut", 0.1 * b, (x, yy, z - 0.14 * b), krem, subdiv=1, scale=(1, 1, 0.4)))
    attach(root, add_ico("kepala", 0.22 * b, (0.72 * b, 0, 0.45 * b), hijau, subdiv=2, scale=(1.2, 0.9, 0.7)))
    add_eyes(root, (-0.1 * b, 0.1 * b), 0.55 * b, gelap, r=0.04 * b, offset=(0.85 * b, 0))
    attach(root, add_cyl("lidah", 0.015 * b, 0.3 * b, (1.05 * b, 0, 0.35 * b), merah, rot=(0, 1.57, 0)))


def build_rusa_raksasa():
    """Rusa tahap 2: gagah dengan tanduk ranting penuh."""
    clear_scene()
    coklat = material("rusa_coklat", (0.62, 0.42, 0.25))
    krem = material("rusa_bintik", (0.85, 0.72, 0.55))
    gelap = material("mata_gelap", (0.1, 0.08, 0.06))
    tanduk_m = material("rusa_tanduk", (0.55, 0.4, 0.22))
    root = root_empty("rusa_raksasa")
    b = 1.5
    attach(root, add_box("badan", (0.95 * b, 0.45 * b, 0.5 * b), (0, 0, 0.95 * b), coklat))
    for x in (-0.28, 0.0, 0.28):
        attach(root, add_ico("bintik", 0.05 * b, (x * b, 0.24 * b, 1.0 * b), krem, subdiv=1))
    attach(root, add_cyl("leher", 0.09 * b, 0.45 * b, (0.5 * b, 0, 1.35 * b), coklat, rot=(0, -0.4, 0)))
    attach(root, add_ico("kepala", 0.16 * b, (0.68 * b, 0, 1.62 * b), coklat, subdiv=2, scale=(1.2, 0.9, 0.9)))
    attach(root, add_box("moncong", (0.14 * b, 0.12 * b, 0.1 * b), (0.85 * b, 0, 1.56 * b), krem))
    add_eyes(root, (-0.08 * b, 0.08 * b), 1.68 * b, gelap, r=0.03 * b, offset=(0.68 * b, 0))
    for y in (-0.15 * b, 0.15 * b):
        attach(root, add_cyl("tanduk_utama", 0.035 * b, 0.6 * b, (0.6 * b, y, 1.95 * b), tanduk_m, rot=(0.3, 0, 0)))
        for j in range(3):
            attach(root, add_cone("ranting", 0.025 * b, 0.3 * b, (0.5 * b - j * 0.08, y * 1.4, 2.1 * b + j * 0.18), tanduk_m, rot=(0.4, 0, y * 0.5)))
    for x in (0.3 * b, -0.3 * b):
        for y in (-0.14 * b, 0.14 * b):
            attach(root, add_cyl("kaki", 0.045 * b, 0.7 * b, (x, y, 0.35 * b), coklat))
    attach(root, add_ico("ekor", 0.07 * b, (-0.5 * b, 0, 1.1 * b), krem))


def build_monyet_emas():
    """Monyet tahap 2: bulu emas mengkilap, ekor panjang anggun."""
    clear_scene()
    emas = material("monyet_emas", (0.9, 0.72, 0.25))
    krem = material("monyet_muka", (0.92, 0.82, 0.66))
    gelap = material("mata_gelap", (0.1, 0.08, 0.06))
    root = root_empty("monyet_emas")
    b = 1.4
    attach(root, add_ico("badan", 0.32 * b, (0, 0, 0.75 * b), emas, subdiv=2, scale=(0.8, 0.7, 1.0)))
    attach(root, add_ico("kepala", 0.3 * b, (0.28 * b, 0, 1.28 * b), emas, subdiv=2))
    attach(root, add_ico("muka", 0.2 * b, (0.42 * b, 0, 1.25 * b), krem, subdiv=2, scale=(0.7, 0.9, 0.9)))
    add_eyes(root, (-0.11 * b, 0.11 * b), 1.32 * b, gelap, r=0.04 * b, offset=(0.44 * b, 0))
    for y in (-0.24 * b, 0.24 * b):
        attach(root, add_ico("telinga", 0.08 * b, (0.22 * b, y, 1.4 * b), emas, subdiv=1))
    for y in (-0.26 * b, 0.26 * b):
        attach(root, add_cyl("lengan", 0.055 * b, 0.6 * b, (0.1 * b, y, 0.5 * b), emas, rot=(0.5, 0, 0)))
    for y in (-0.16 * b, 0.16 * b):
        attach(root, add_cyl("kaki", 0.06 * b, 0.45 * b, (-0.08 * b, y, 0.22 * b), emas))
    attach(root, add_cyl("ekor", 0.04 * b, 0.8 * b, (-0.42 * b, 0, 1.0 * b), emas, rot=(0, 1.1, 0)))
    attach(root, add_cyl("ekor_atas", 0.04 * b, 0.5 * b, (-0.75 * b, 0, 1.35 * b), emas, rot=(0.9, 1.1, 0)))


def build_ayam_satria():
    """Ayam tahap 2: jago perkasa — jengger besar, taji, ekor melengkung tinggi."""
    clear_scene()
    merah = material("ayam_merah", (0.85, 0.2, 0.15))
    coklat = material("ayam_coklat", (0.72, 0.45, 0.2))
    oranye = material("ayam_oranye", (0.95, 0.55, 0.1))
    biru = material("ayam_ekor", (0.2, 0.25, 0.4))
    gelap = material("mata_gelap", (0.1, 0.08, 0.06))
    root = root_empty("ayam_satria")
    b = 1.35
    attach(root, add_ico("badan", 0.42 * b, (0, 0, 0.75 * b), coklat, subdiv=2, scale=(1.15, 0.8, 1.0)))
    attach(root, add_cyl("leher", 0.12 * b, 0.45 * b, (0.3 * b, 0, 1.25 * b), coklat, rot=(0, 0.4, 0)))
    attach(root, add_ico("kepala", 0.17 * b, (0.45 * b, 0, 1.55 * b), coklat, subdiv=2))
    attach(root, add_box("jengger", (0.32 * b, 0.08 * b, 0.18 * b), (0.45 * b, 0, 1.78 * b), merah))
    attach(root, add_cone("paruh", 0.06 * b, 0.16 * b, (0.62 * b, 0, 1.55 * b), oranye, rot=(0, -1.57, 0)))
    for y in (-0.12 * b, 0.12 * b):
        attach(root, add_ico("mata", 0.03 * b, (0.53 * b, y, 1.6 * b), gelap))
        attach(root, add_box("pial", (0.06 * b, 0.04 * b, 0.16 * b), (0.5 * b, y, 1.42 * b), merah))
    for i in range(4):
        attach(root, add_cone("ekor", 0.08 * b, 0.65 * b, (-0.55 * b, (i - 1.5) * 0.12 * b, 1.15 * b + i * 0.08), biru if i % 2 else merah, rot=(0, 1.0 + i * 0.14, 0)))
    for y in (-0.12 * b, 0.12 * b):
        attach(root, add_cyl("kaki", 0.035 * b, 0.5 * b, (0.05, y, 0.25 * b), oranye))
        attach(root, add_box("cakar", (0.16 * b, 0.05 * b, 0.04 * b), (0.13 * b, y, 0.05), oranye))
        attach(root, add_cone("taji", 0.02 * b, 0.15 * b, (0.15 * b, y * 1.4, 0.25 * b), gelap, rot=(0, 0, 1.3)))


def build_kupu(tahap):
    """Ulat Daun → Kupu-kupu Ekor Walet: metamorfosis lengkap."""
    clear_scene()
    hijau = material("ulat_hijau", (0.4, 0.65, 0.25))
    gelap = material("mata_gelap", (0.07, 0.07, 0.05))
    if tahap == 0:
        root = root_empty("ulat_daun")
        for i in range(5):
            attach(root, add_ico("ruas", 0.2 - i * 0.015, (0.35 - i * 0.32, 0, 0.2), hijau, subdiv=2))
            for y in (-0.12, 0.12):
                attach(root, add_cyl("kaki", 0.03, 0.08, (0.35 - i * 0.32, y, 0.06), hijau))
        attach(root, add_ico("kepala", 0.17, (0.62, 0, 0.28), hijau, subdiv=2))
        add_eyes(root, (-0.06, 0.06), 0.33, gelap, r=0.03, offset=(0.68, 0))
        attach(root, add_cone("antena", 0.02, 0.12, (0.66, -0.06, 0.45), hijau))
        attach(root, add_cone("antena", 0.02, 0.12, (0.66, 0.06, 0.45), hijau))
    else:
        biru = material("kupu_biru", (0.25, 0.4, 0.75))
        putih = material("kupu_motif", (0.92, 0.9, 0.85))
        hitam = material("kupu_tubuh", (0.2, 0.18, 0.2))
        root = root_empty("kupu-kupu_ekor_walet")
        attach(root, add_ico("badan", 0.16, (0, 0, 0.7), hitam, subdiv=2, scale=(2.0, 0.6, 0.6)))
        attach(root, add_ico("kepala", 0.11, (0.35, 0, 0.75), hitam, subdiv=2))
        add_eyes(root, (-0.04, 0.04), 0.78, gelap, r=0.025, offset=(0.42, 0))
        for y in (-0.04, 0.04):
            attach(root, add_cyl("antena", 0.008, 0.3, (0.42, y, 0.9), hitam, rot=(0.5, 0, 0)))
            attach(root, add_ico("ujung_antena", 0.015, (0.5, y * 1.6, 1.05), hitam, subdiv=1))
        for y in (-1, 1):
            attach(root, add_box("sayap_atas", (0.55, 0.75, 0.04), (0.05, y * 0.5, 0.85), biru, rot=(0.2, 0, y * 0.3)))
            attach(root, add_box("sayap_bawah", (0.4, 0.55, 0.04), (-0.15, y * 0.45, 0.55), biru, rot=(-0.2, 0, y * 0.25)))
            attach(root, add_ico("mata_sayap", 0.08, (0.1, y * 0.6, 0.9), putih, subdiv=1, scale=(1, 1, 0.3)))
            attach(root, add_cone("ekor_walet", 0.05, 0.3, (-0.45, y * 0.3, 0.55), hitam, rot=(0, -1.2, 0)))


def build_udang(tahap):
    """Udang Kecil→Raksasa: badan melengkung bersegmen, antena, capung."""
    clear_scene()
    merah = material("udang_merah", (0.85, 0.4, 0.25))
    krem = material("udang_perut", (0.92, 0.85, 0.75))
    gelap = material("mata_gelap", (0.06, 0.05, 0.05))
    b = 1.5 if tahap >= 1 else 0.85
    root = root_empty("udang_tahap%d" % tahap)
    for i in range(6):
        x = 0.5 * b - i * 0.22 * b
        z = 0.45 * b + (0.18 * b if i > 2 else -0.05 * b * i)
        attach(root, add_ico("ruas", 0.16 * b * (1.0 - i * 0.07), (x, 0, z), merah, subdiv=2))
        attach(root, add_ico("perut", 0.09 * b, (x, 0, z - 0.13 * b), krem, subdiv=1, scale=(1, 1, 0.4)))
    attach(root, add_ico("kepala", 0.15 * b, (0.75 * b, 0, 0.4 * b), merah, subdiv=2))
    add_eyes(root, (-0.07 * b, 0.07 * b), 0.45 * b, gelap, r=0.04 * b, offset=(0.85 * b, 0))
    for y in (-1, 1):
        attach(root, add_cyl("antena", 0.01 * b, 0.9 * b, (0.9 * b, y * 0.15 * b, 0.5 * b), merah, rot=(0, 1.3, y * 0.25)))
    for y in (-0.18 * b, 0.18 * b):
        attach(root, add_cyl("lengan_capung", 0.035 * b, 0.3 * b, (0.6 * b, y, 0.3 * b), merah, rot=(0, 0.6, 0)))
        attach(root, add_box("capung", (0.18 * b, 0.06 * b, 0.05 * b), (0.82 * b, y * 1.2, 0.25 * b), krem))
    for i in range(4):
        for y in (-0.14 * b, 0.14 * b):
            attach(root, add_cyl("kaki", 0.02 * b, 0.14 * b, (0.3 * b - i * 0.22 * b, y, 0.2 * b), merah, rot=(0.4, 0, 0)))
    attach(root, add_box("ekor", (0.3 * b, 0.35 * b, 0.05 * b), (-0.85 * b, 0, 0.75 * b), krem, rot=(0, 0.8, 0)))


def build_kepiting(tahap):
    """Kepiting Kecil→Kenari: cangkang pipih, capung besar; dewasa bercangkang tebal."""
    clear_scene()
    oranye = material("kepiting_oranye", (0.85, 0.45, 0.15))
    krem = material("kepiting_perut", (0.92, 0.82, 0.65))
    gelap = material("mata_gelap", (0.06, 0.05, 0.05))
    b = 1.5 if tahap >= 1 else 0.85
    root = root_empty("kepiting_tahap%d" % tahap)
    attach(root, add_ico("cangkang", 0.42 * b, (0, 0, 0.42 * b), oranye, subdiv=2, scale=(1.15, 0.95, 0.55)))
    attach(root, add_ico("perut", 0.32 * b, (0, 0, 0.18 * b), krem, subdiv=2, scale=(1.05, 0.85, 0.3)))
    for y in (-0.1 * b, 0.1 * b):
        attach(root, add_cyl("batang_mata", 0.02 * b, 0.12 * b, (0.35 * b, y, 0.55 * b), oranye))
        attach(root, add_ico("mata", 0.035 * b, (0.35 * b, y, 0.62 * b), gelap, subdiv=1))
    for y in (-1, 1):
        attach(root, add_cyl("lengan_capung", 0.05 * b, 0.4 * b, (0.25 * b, y * 0.55 * b, 0.35 * b), oranye, rot=(1.2, 0, 0)))
        attach(root, add_box("capung", (0.2 * b, 0.3 * b, 0.1 * b), (0.3 * b, y * 0.8 * b, 0.25 * b), oranye))
    for i in range(3):
        for y in (-1, 1):
            attach(root, add_cyl("kaki", 0.025 * b, 0.45 * b, (-0.1 * b + i * 0.18 * b, y * 0.45 * b, 0.25 * b), oranye, rot=(0.3, 0, y * 0.6)))


def build_ikan_badut():
    """Ikan Badut (single-stage): badan oranye bergaris putih, sirip bulat."""
    clear_scene()
    oranye = material("badut_oranye", (0.95, 0.5, 0.15))
    putih = material("badut_garis", (0.95, 0.95, 0.92))
    hitam = material("badut_pinggir", (0.15, 0.12, 0.1))
    gelap = material("mata_gelap", (0.06, 0.05, 0.05))
    root = root_empty("ikan_badut")
    attach(root, add_ico("badan", 0.35, (0, 0, 0.55), oranye, subdiv=2, scale=(1.3, 0.55, 0.75)))
    for x in (0.25, -0.05, -0.35):
        attach(root, add_ico("garis", 0.28, (x, 0, 0.55), putih, subdiv=2, scale=(0.08, 0.58, 0.78)))
        attach(root, add_ico("pinggir", 0.285, (x + 0.06, 0, 0.55), hitam, subdiv=2, scale=(0.05, 0.58, 0.78)))
    attach(root, add_cone("moncong", 0.16, 0.2, (0.5, 0, 0.55), oranye, rot=(0, 1.57, 0)))
    add_eyes(root, (-0.12, 0.12), 0.65, gelap, r=0.05, offset=(0.35, 0))
    attach(root, add_cone("sirip_punggung", 0.1, 0.25, (-0.05, 0, 0.95), oranye))
    for y in (-0.28, 0.28):
        attach(root, add_box("sirip_samping", (0.2, 0.15, 0.04), (0.15, y, 0.45), oranye, rot=(0, 0.5, 0)))
    attach(root, add_box("ekor", (0.25, 0.35, 0.05), (-0.55, 0, 0.55), oranye, rot=(0, 0.6, 0)))


def build_ikan_buntal(tahap):
    """Ikan Buntal Kecil→Raksasa: menggembung & berduri saat dewasa, beracun."""
    clear_scene()
    coklat = material("buntal_coklat", (0.65, 0.5, 0.3))
    krem = material("buntal_perut", (0.92, 0.88, 0.75))
    gelap = material("mata_gelap", (0.06, 0.05, 0.05))
    b = 1.5 if tahap >= 1 else 0.85
    root = root_empty("ikan_buntal_tahap%d" % tahap)
    attach(root, add_ico("badan", 0.4 * b, (0, 0, 0.55 * b), coklat, subdiv=2, scale=(1.15, 0.75, 0.85)))
    attach(root, add_ico("perut", 0.3 * b, (0, 0, 0.4 * b), krem, subdiv=2, scale=(1.0, 0.65, 0.5)))
    attach(root, add_cone("moncong", 0.12 * b, 0.2 * b, (0.5 * b, 0, 0.55 * b), coklat, rot=(0, 1.57, 0)))
    add_eyes(root, (-0.13 * b, 0.13 * b), 0.65 * b, gelap, r=0.06 * b, offset=(0.35 * b, 0))
    attach(root, add_cone("sirip_punggung", 0.08 * b, 0.2 * b, (-0.1, 0, 0.9 * b), coklat))
    for y in (-0.25 * b, 0.25 * b):
        attach(root, add_box("sirip_samping", (0.18 * b, 0.12 * b, 0.04 * b), (0.1, y, 0.45 * b), krem, rot=(0, 0.5, 0)))
    attach(root, add_box("ekor", (0.22 * b, 0.3 * b, 0.05 * b), (-0.55 * b, 0, 0.55 * b), coklat, rot=(0, 0.6, 0)))
    if tahap >= 1:
        # duri racun menyembul saat menggembung (ciri buntal raksasa)
        for i, (dx, dy) in enumerate(((0.3, 0.3), (0.3, -0.3), (-0.1, 0.42), (-0.1, -0.42), (-0.45, 0.2), (-0.45, -0.2))):
            attach(root, add_cone("duri_racun", 0.03 * b, 0.16 * b, (dx * b, dy * b, 0.62 * b), krem))


def build_kantong_semar(tahap):
    """Kantong Semar Kecil→Raksasa: pitchers memanjat; dewasa berdaun racun."""
    clear_scene()
    hijau = material("semar_hijau", (0.35, 0.6, 0.25))
    merah = material("semar_pitcher", (0.75, 0.3, 0.2))
    tutup_m = material("semar_tutup", (0.5, 0.7, 0.3))
    gelap = material("mata_gelap", (0.07, 0.07, 0.05))
    b = 1.5 if tahap >= 1 else 0.85
    root = root_empty("kantong_semar_tahap%d" % tahap)
    attach(root, add_cyl("batang", 0.07 * b, 0.8 * b, (0, 0, 0.4 * b), hijau))
    # dua pitcher (kantong) menggantung
    for y in (-0.3 * b, 0.3 * b):
        attach(root, add_cone("pitcher", 0.16 * b, 0.42 * b, (0.25 * b, y, 0.55 * b), merah))
        attach(root, add_cyl("mulut_pitcher", 0.13 * b, 0.05 * b, (0.25 * b, y, 0.78 * b), merah))
        attach(root, add_ico("tutup", 0.12 * b, (0.25 * b, y, 0.84 * b), tutup_m, subdiv=2, scale=(1.0, 0.8, 0.3)))
        attach(root, add_cyl("tali_pitcher", 0.015 * b, 0.25 * b, (0.1 * b, y, 0.68 * b), hijau, rot=(0, 0.9, 0)))
    # daun
    for y in (-1, 1):
        attach(root, add_box("daun", (0.4 * b, 0.18 * b, 0.04 * b), (-0.15 * b, y * 0.25 * b, 0.85 * b), hijau, rot=(0.4, 0, y * 0.5)))
    if tahap >= 1:
        # pitcher ketiga lebih besar + daun racun gelap
        attach(root, add_cone("pitcher_besar", 0.2 * b, 0.55 * b, (-0.35 * b, 0, 0.75 * b), merah))
        attach(root, add_ico("tutup_besar", 0.15 * b, (-0.35 * b, 0, 1.05 * b), tutup_m, subdiv=2, scale=(1.0, 0.8, 0.3)))
        for y in (-1, 1):
            attach(root, add_box("daun_racun", (0.35 * b, 0.15 * b, 0.04 * b), (-0.4 * b, y * 0.35 * b, 1.1 * b), gelap, rot=(0.5, 0, y * 0.7)))


# ---------------------------------------------------------------- registry & CLI

BUILDERS = {
    # MVP (Fase 1-4) — tahap dasar starter & fauna Jawa
    "anak_rimau": build_anak_rimau,
    "orangkici": build_orangkici,
    "penyuci": build_penyuci,
    "monyet_kecil": build_monyet_kecil,
    "ayam_jantan": build_ayam_jantan,
    "rusa_muda": build_rusa_muda,
    # Fase 5 — evolusi starter
    "rimau_muda": lambda: build_rimau(1),
    "rimau_agung": lambda: build_rimau(2),
    "oranguda": lambda: build_orangutan(1),
    "orangraja": lambda: build_orangutan(2),
    "penyula": lambda: build_penyu(1),
    "samudragon": lambda: build_penyu(2),
    # Fase 5 — legendary (single-stage)
    "elang_garuda": build_elang_garuda,
    "cenderawasih_agung": build_cenderawasih_agung,
    "paus_samudra": build_paus_samudra,
    # Fase 5 — pseudo-legendary (3 tahap)
    "biawak_kecil": lambda: build_biawak(0),
    "komodo": lambda: build_biawak(1),
    "komodo_raja": lambda: build_biawak(2),
    "gajah_sapi": lambda: build_gajah(0),
    "gajah_sumatra": lambda: build_gajah(1),
    "gajah_raksasa": lambda: build_gajah(2),
    "badak_muda": lambda: build_badak(0),
    "badak_sumatra": lambda: build_badak(1),
    "badak_baja": lambda: build_badak(2),
    # Fase 5 — rare (2 tahap)
    "hiu_kecil": lambda: build_hiu(0),
    "hiu_raksasa": lambda: build_hiu(1),
    "buaya_kecil": lambda: build_buaya(0),
    "buaya_raksasa": lambda: build_buaya(1),
    "banteng_muda": lambda: build_banteng(0),
    "banteng_murba": lambda: build_banteng(1),
    "babirusa_muda": lambda: build_babirusa(0),
    "babirusa_raksasa": lambda: build_babirusa(1),
    "beruang_muda": lambda: build_beruang(0),
    "beruang_madu": lambda: build_beruang(1),
    "rangkong_muda": lambda: build_rangkong(0),
    "rangkong_agung": lambda: build_rangkong(1),
    "merak_muda": lambda: build_merak(0),
    "merak_agung": lambda: build_merak(1),
    "lumba_kecil": lambda: build_lumba(0),
    "lumba_petir": lambda: build_lumba(1),
    "arwana_kecil": lambda: build_arwana(0),
    "arwana_naga": lambda: build_arwana(1),
    "gurita_kecil": lambda: build_gurita(0),
    "gurita_raksasa": lambda: build_gurita(1),
    # Fase 5 — uncommon
    "kakatua_muda": lambda: build_kakatua(0),
    "kakatua_raja": lambda: build_kakatua(1),
    "ular_kecil": lambda: build_ular(0),
    "ular_raksasa": lambda: build_ular(1),
    # Fase 5 — evolusi fauna Common Jawa
    "rusa_raksasa": build_rusa_raksasa,
    "monyet_emas": build_monyet_emas,
    "ayam_satria": build_ayam_satria,
    # Fase 5 — common sisanya
    "ulat_daun": lambda: build_kupu(0),
    "kupu-kupu_ekor_walet": lambda: build_kupu(1),
    "udang_kecil": lambda: build_udang(0),
    "udang_raksasa": lambda: build_udang(1),
    "kepiting_kecil": lambda: build_kepiting(0),
    "kepiting_kenari": lambda: build_kepiting(1),
    "ikan_badut": build_ikan_badut,
    "ikan_buntal_kecil": lambda: build_ikan_buntal(0),
    "ikan_buntal_raksasa": lambda: build_ikan_buntal(1),
    "kantong_semar_kecil": lambda: build_kantong_semar(0),
    "kantong_semar_raksasa": lambda: build_kantong_semar(1),
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
