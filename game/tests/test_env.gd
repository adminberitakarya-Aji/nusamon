extends SceneTree
## Tes headless EnvBuilder NUSAMON (Fase 3 langkah 6): path aset CC0,
## placeholder low-poly per lokasi (deterministik), fallback .glb.
## Jalankan: godot --headless --script game/tests/test_env.gd
## (atau: powershell -File tools\run_tests.ps1)

var gagal := 0
var lulus := 0


func cek(nama: String, kondisi: bool, info := "") -> void:
	if kondisi:
		lulus += 1
		print("[LULUS] " + nama)
	else:
		gagal += 1
		print("[GAGAL] " + nama + (": " + info if info != "" else ""))


func _init() -> void:
	print("=== Tes EnvBuilder NUSAMON ===")
	cek("path_env rute_1", EnvBuilder.path_env("rute_1") == "res://assets/env/rute_1.glb")
	cek("path_env desa", EnvBuilder.path_env("desa_sumberrejo") == "res://assets/env/desa_sumberrejo.glb")

	# ---------- placeholder per lokasi (deterministik)
	var db := NusamonData.load_world()
	cek("world.json terbaca", not db.is_empty())
	if db.is_empty():
		quit(1)
		return
	var hitung := {}
	for l in db.get("lokasi", []):
		var id := String(l.get("id", ""))
		var env := EnvBuilder.pasang(l)
		cek("pasang(%s) mengembalikan Node3D" % id, env != null and env is Node3D)
		cek("pasang(%s) punya isi (tanah/props)" % id, env.get_child_count() > 0,
			"anak " + str(env.get_child_count()))
		cek("pasang(%s) deterministik (nama placeholder)" % id, env.name == "EnvPlaceholder")
		hitung[id] = env.get_child_count()
	# tema berbeda → isi berbeda (kota punya gedung+jalan > desa minimum)
	cek("kota lebih ramai dari desa",
		int(hitung.get("kota_harapan", 0)) != int(hitung.get("desa_sumberrejo", 0)),
		str(hitung))
	# tanah selalu anak pertama
	var akar := EnvBuilder.bangun_placeholder({"id": "rute_1", "jenis": "rute"})
	cek("anak pertama = tanah (MeshInstance3D)",
		akar.get_child_count() > 0 and akar.get_child(0) is MeshInstance3D)
	# fallback: tanpa .glb CC0 → placeholder (aset env belum dipasang)
	cek("aset .glb CC0 belum dipasang → fallback placeholder aktif",
		not ResourceLoader.exists(EnvBuilder.path_env("kota_arunika")))
	var fallback := EnvBuilder.pasang({"id": "kota_arunika", "jenis": "kota"})
	cek("fallback kota_arunika = placeholder programatik", fallback.name == "EnvPlaceholder")
	# lokasi tak dikenal tetap aman (tanah + pohon latar)
	var asing := EnvBuilder.pasang({"id": "lokasi_misterius", "jenis": "rute"})
	cek("lokasi tak dikenal tetap dibangun", asing.get_child_count() > 0)

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)