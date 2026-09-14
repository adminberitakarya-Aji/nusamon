class_name EnvBuilder
extends RefCounted
## Builder environment dunia NUSAMON (static) — Fase 3 langkah 6.
## Sumber aset resmi: pustaka CC0 (Kenney/Quaternius) — pasang file
## assets/env/<id_lokasi>.glb (panduan: assets/env/README.md).
## Bila .glb belum ada → placeholder low-poly programatik per tema lokasi
## (konvensi fallback pratinjau model monster — D-1). Deterministik (tanpa RNG)
## → testable headless.

const DIR_ENV := "res://assets/env/"

const WARNA_TANAH := {
	"desa": Color(0.5, 0.72, 0.38),
	"rute": Color(0.42, 0.68, 0.42),
	"kota": Color(0.55, 0.58, 0.5),
}


## Path aset environment sebuah lokasi.
static func path_env(id_lokasi: String) -> String:
	return DIR_ENV + id_lokasi + ".glb"


## Pasang environment lokasi: .glb CC0 bila ada, selain itu placeholder.
static func pasang(lokasi: Dictionary) -> Node3D:
	var path := path_env(String(lokasi.get("id", "")))
	if ResourceLoader.exists(path):
		var paket: PackedScene = load(path)
		if paket != null:
			var inst: Node3D = paket.instantiate()
			if inst != null:
				return inst
	return bangun_placeholder(lokasi)


## Placeholder low-poly per tema lokasi (deterministik).
static func bangun_placeholder(lokasi: Dictionary) -> Node3D:
	var akar := Node3D.new()
	akar.name = "EnvPlaceholder"
	_tanah(akar, String(lokasi.get("jenis", "rute")))
	match String(lokasi.get("id", "")):
		"desa_sumberrejo":
			_rumah(akar, Vector3(-4, 0, -3))
			_rumah(akar, Vector3(4, 0, -4))
			_rumah(akar, Vector3(0, 0, 3))
			_pohon(akar, Vector3(-7, 0, 2))
			_pohon(akar, Vector3(7, 0, 4))
			_pohon(akar, Vector3(-6, 0, -6))
			_pohon(akar, Vector3(8, 0, -2))
		"rute_1":
			_sawah(akar)
			_pohon(akar, Vector3(-8, 0, 4))
			_pohon(akar, Vector3(9, 0, -5))
		"rute_2":
			_gunung(akar)
			_pohon(akar, Vector3(-6, 0, 3))
			_pohon(akar, Vector3(6, 0, 4))
		"kota_harapan", "kota_arunika":
			_kota(akar)
		_:
			_pohon(akar, Vector3(-5, 0, -5))
			_pohon(akar, Vector3(5, 0, 5))
	return akar


# ------------------------------------------------------------ primitif

static func _kotak(n: Node3D, ukuran: Vector3, pos: Vector3, warna: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = ukuran
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = warna
	mi.material_override = mat
	mi.position = pos
	n.add_child(mi)
	return mi


static func _tanah(n: Node3D, jenis: String) -> void:
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	mi.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = WARNA_TANAH.get(jenis, Color(0.42, 0.68, 0.42))
	mi.material_override = mat
	n.add_child(mi)


static func _pohon(n: Node3D, pos: Vector3) -> void:
	_kotak(n, Vector3(0.35, 1.2, 0.35), pos + Vector3(0, 0.6, 0), Color(0.42, 0.28, 0.18))
	_kotak(n, Vector3(1.5, 1.5, 1.5), pos + Vector3(0, 1.9, 0), Color(0.18, 0.52, 0.24))


static func _rumah(n: Node3D, pos: Vector3) -> void:
	_kotak(n, Vector3(2.4, 1.6, 2.4), pos + Vector3(0, 0.8, 0), Color(0.85, 0.8, 0.7))
	_kotak(n, Vector3(2.8, 0.6, 2.8), pos + Vector3(0, 1.9, 0), Color(0.68, 0.24, 0.2))


static func _gedung(n: Node3D, pos: Vector3, tinggi: float, warna: Color) -> void:
	_kotak(n, Vector3(2.2, tinggi, 2.2), pos + Vector3(0, tinggi / 2.0, 0), warna)


static func _sawah(n: Node3D) -> void:
	# petak sawah bertingkat + barisan padi
	for baris in 4:
		for kolom in 6:
			var warna := Color(0.55, 0.78, 0.3) if (baris + kolom) % 2 == 0 else Color(0.62, 0.82, 0.35)
			_kotak(n, Vector3(1.6, 0.25, 1.6),
				Vector3(-7.0 + kolom * 2.6, 0.12 + baris * 0.35, -4.0 + baris * 2.4), warna)


static func _kota(n: Node3D) -> void:
	# jalan
	_kotak(n, Vector3(40, 0.05, 2.6), Vector3(0, 0.03, 0), Color(0.4, 0.4, 0.38))
	_gedung(n, Vector3(-6, 0, -4), 3.2, Color(0.8, 0.75, 0.65))
	_gedung(n, Vector3(6, 0, -5), 4.4, Color(0.72, 0.68, 0.6))
	_gedung(n, Vector3(-5, 0, 5), 2.6, Color(0.85, 0.78, 0.6))
	_gedung(n, Vector3(6, 0, 5), 3.8, Color(0.7, 0.6, 0.55))
	_pohon(n, Vector3(0, 0, 6))


static func _gunung(n: Node3D) -> void:
	# Gunung Kapi: kerucut + bebatuan
	var mi := MeshInstance3D.new()
	var kerucut := CylinderMesh.new()
	kerucut.top_radius = 0.4
	kerucut.bottom_radius = 6.5
	kerucut.height = 9.0
	mi.mesh = kerucut
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.46, 0.42, 0.4)
	mi.material_override = mat
	mi.position = Vector3(0, 4.5, -8)
	n.add_child(mi)
	_kotak(n, Vector3(1.4, 1.0, 1.4), Vector3(-4, 0.5, 2), Color(0.55, 0.52, 0.5))
	_kotak(n, Vector3(1.0, 0.7, 1.0), Vector3(4, 0.35, -2), Color(0.55, 0.52, 0.5))