extends SceneTree
## Tes headless pusat pemulihan + toko dunia (Fase 4 langkah 4): POI aksi,
## pulihkan tim, toko semua tier (Nusantara = event), guard anti-softlock battle.
## Jalankan: godot --headless --script game/tests/test_pusat.gd
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
	_mulai.call_deferred()


func _mulai() -> void:
	print("=== Tes Pusat Pemulihan & Toko NUSAMON ===")
	var dunia := NusamonData.load_world()
	var nusamons := NusamonData.load_nusamons()
	cek("world.json terbaca", not dunia.is_empty())
	cek("nusamons.json terbaca", not nusamons.is_empty())
	if dunia.is_empty() or nusamons.is_empty():
		quit(1)
		return

	# ---------- 1. data POI pusat & toko di kedua kota
	for kota in ["kota_harapan", "kota_arunika"]:
		var lok := WorldEngine.lokasi(dunia, kota)
		var aksi_ada := {}
		for t in lok.get("tempat", []):
			aksi_ada[String(t.get("aksi", ""))] = true
		cek("%s: punya pusat pemulihan (aksi pulihkan)" % kota, aksi_ada.has("pulihkan"))
		cek("%s: punya toko (aksi toko)" % kota, aksi_ada.has("toko"))

	# ---------- 2. world scene: pulihkan tim rusak
	Inventori.reset()
	Tim.reset()
	Nusadex.reset()
	Simpanan.hapus()
	Progres.reset()
	Progres.lokasi = "kota_harapan"
	var paket: PackedScene = load("res://game/world/world_scene.tscn")
	var wscene: Control = paket.instantiate()
	root.add_child(wscene)
	cek("world scene termuat", wscene != null)
	# tanpa mon → ditolak
	wscene._pulihkan_tim()
	cek("pulihkan tanpa mon ditolak",
		wscene.log_label.text.contains("Belum punya Nusamon"))
	# tim rusak → pulihkan penuh
	var m_rusak := NusamonInstance.create(
		NusamonData.find_species(nusamons, 1), nusamons["detailSpesies"]["1"], 0, 5)
	m_rusak.take_damage(m_rusak.max_hp - 1)
	m_rusak.status = "racun"
	Tim.tambah(m_rusak)
	wscene._pulihkan_tim()
	cek("HP pulih penuh", int(m_rusak.current_hp) == int(m_rusak.max_hp))
	cek("status dibersihkan", m_rusak.status == "")
	cek("pulihkan tersimpan otomatis", FileAccess.file_exists(Simpanan.PATH))

	# ---------- 3. toko dunia: semua tier, Nusantara = event
	wscene._buka_toko_dunia()
	cek("overlay toko terbuka", wscene.toko_overlay != null)
	var stok_amukan := Inventori.stok_item("amukan")
	var uang := int(Inventori.uang)
	wscene._beli_toko("amukan")
	cek("beli amukan (tier dasar) berhasil",
		Inventori.stok_item("amukan") == stok_amukan + 1 and int(Inventori.uang) == uang - 200)
	wscene._beli_toko("amukan_nusantara")
	cek("amukan_nusantara tidak bisa dibeli (hadiah event)",
		Inventori.stok_item("amukan_nusantara") == 0 and int(Inventori.uang) == uang - 200)
	wscene._tutup_toko()
	cek("overlay toko tertutup", wscene.toko_overlay == null)

	# ---------- 4. battle: TANPA auto-heal — guard anti-softlock
	Progres.pilih_starter(1)   # Rimau (placeholder tak relevan — Tim sudah ada)
	TrainerEngine.set_antrean("")
	EncounterSystem.reset()
	var paket_b: PackedScene = load("res://game/battle/battle_scene.tscn")
	# 4a. aktif pingsan + anggota sehat → anggota sehat maju (bukan heal)
	Simpanan.hapus()
	Tim.reset()
	var m1 := NusamonInstance.create(
		NusamonData.find_species(nusamons, 1), nusamons["detailSpesies"]["1"], 0, 5)
	var m2 := NusamonInstance.create(
		NusamonData.find_species(nusamons, 22), nusamons["detailSpesies"]["22"], 0, 5)
	m1.take_damage(m1.max_hp)   # pingsan
	Tim.tambah(m1)
	Tim.tambah(m2)
	var scene: Control = paket_b.instantiate()
	root.add_child(scene)
	cek("mon aktif pingsan → anggota sehat maju",
		scene.player == m2 and not bool(scene.log_label.text.contains("dipulihkan darurat")),
		"aktif " + String(scene.player.display_name))
	cek("mon pingsan TETAP pingsan (tidak di-auto-heal)", m1.is_fainted())
	# 4b. seluruh tim pingsan → pemulihan darurat (anti-softlock)
	Progres.reset()
	Progres.pilih_starter(1)
	Tim.reset()
	var m3 := NusamonInstance.create(
		NusamonData.find_species(nusamons, 1), nusamons["detailSpesies"]["1"], 0, 5)
	m3.take_damage(m3.max_hp)
	Tim.tambah(m3)
	Simpanan.hapus()
	var scene2: Control = paket_b.instantiate()
	root.add_child(scene2)
	cek("seluruh tim pingsan → dipulihkan darurat",
		int(scene2.player.current_hp) == int(scene2.player.max_hp)
		and scene2.log_label.text.contains("dipulihkan darurat"))

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)