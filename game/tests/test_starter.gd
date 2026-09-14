extends SceneTree
## Tes headless starter selection + cutscene (Fase 4 langkah 1): data POI lab,
## Progres starter (terkunci sekali), cutscene world scene → starter masuk tim,
## gating encounter/gym, starter dipakai battle scene, persistensi.
## Jalankan: godot --headless --script game/tests/test_starter.gd
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
	print("=== Tes Starter Selection NUSAMON ===")
	var dunia := NusamonData.load_world()
	var nusamons := NusamonData.load_nusamons()
	cek("world.json terbaca", not dunia.is_empty())
	cek("nusamons.json terbaca", not nusamons.is_empty())
	if dunia.is_empty() or nusamons.is_empty():
		quit(1)
		return

	# ---------- 1. data POI lab (data-driven)
	var lab := WorldEngine.lokasi(dunia, "desa_sumberrejo")
	var poi_lab := {}
	for t in lab.get("tempat", []):
		if String(t.get("id", "")) == "lab_candri":
			poi_lab = t
	cek("POI lab_candri ada", not poi_lab.is_empty())
	cek("POI lab aksi = pilih_starter", String(poi_lab.get("aksi", "")) == "pilih_starter")
	cek("POI lab punya dialog cutscene (>=3 baris)",
		(poi_lab.get("dialog", []) as Array).size() >= 3)

	# ---------- 2. data starter trio (roster: Rimau/Orangutan/Penyu)
	var trio_ok := true
	for pasangan in [[1, "Anak Rimau", "Api"], [2, "Orangkici", "Daun"], [3, "Penyuci", "Air"]]:
		var sp := NusamonData.find_species(nusamons, pasangan[0])
		if sp.is_empty() or String(sp.get("rarity", "")) != "starter":
			trio_ok = false
			continue
		var t0: Dictionary = sp.get("tahapan", [{}])[0]
		if String(t0.get("nama", "")) != pasangan[1] or not (t0.get("tipe", []) as Array).has(pasangan[2]):
			trio_ok = false
	cek("trio starter (1/2/3): rarity starter + nama & tipe tahap 0 benar", trio_ok)

	# ---------- 3. Progres starter: terkunci sekali
	Progres.reset()
	cek("belum memilih starter", not Progres.sudah_pilih_starter())
	Progres.pilih_starter(2)
	Progres.pilih_starter(1)   # harus ditolak — sekali pilih
	cek("starter terkunci (tidak bisa diganti)",
		int(Progres.starter_id) == 2 and Progres.sudah_pilih_starter())
	Progres.reset()
	cek("reset menghapus starter", not Progres.sudah_pilih_starter())

	# ---------- 4. cutscene world scene → starter masuk tim
	Inventori.reset()
	Tim.reset()
	Nusadex.reset()
	Simpanan.hapus()
	Progres.reset()
	Progres.lokasi = "desa_sumberrejo"
	var paket: PackedScene = load("res://game/world/world_scene.tscn")
	cek("world scene termuat", paket != null)
	if paket == null:
		quit(1)
		return
	var dunia_scene: Control = paket.instantiate()
	root.add_child(dunia_scene)
	# gating: tanpa starter, encounter & gym ditolak
	dunia_scene._cari_encounter()
	cek("encounter ditolak tanpa starter",
		dunia_scene.log_label.text.contains("Pilih Nusamon pertamamu"))
	dunia_scene._tantang_gym("bu_sari")
	cek("gym ditolak tanpa starter",
		dunia_scene.log_label.text.contains("Pilih Nusamon pertamamu"))
	# cutscene: buka → lanjut melewati dialog → muncul pilihan → pilih Orangkici (2)
	dunia_scene._buka_cutscene_starter()
	cek("cutscene overlay terbuka", dunia_scene.cutscene_overlay != null)
	cek("cutscene baris terisi dari data", dunia_scene.cutscene_baris.size() >= 3)
	for i in dunia_scene.cutscene_baris.size():
		dunia_scene._tampilkan_langkah_cutscene()
		dunia_scene.cutscene_idx += 1
	dunia_scene._tampilkan_langkah_cutscene()
	cek("setelah dialog habis → langkah pilihan (overlay tetap)",
		dunia_scene.cutscene_overlay != null and dunia_scene.cutscene_idx >= dunia_scene.cutscene_baris.size())
	dunia_scene._pilih_starter(2)
	cek("starter tersimpan di progres", int(Progres.starter_id) == 2)
	cek("starter masuk tim (1 anggota)", Tim.jumlah() == 1)
	cek("starter = Orangkici Lv.5",
		String(Tim.aktif().display_name) == "Orangkici" and int(Tim.aktif().level) == 5)
	cek("tipe starter = Daun", (Tim.aktif().types as Array).has("Daun"))
	cek("nusadex: starter terlihat & tertangkap",
		Nusadex.sudah_lihat(2) and Nusadex.sudah_tangkap(2))
	cek("cutscene ditutup setelah memilih", dunia_scene.cutscene_overlay == null)
	cek("log: ucapan perpisahan Prof. Candri",
		dunia_scene.log_label.text.contains("Pilihan bagus"))
	cek("starter tersimpan otomatis", FileAccess.file_exists(Simpanan.PATH))
	# pilih ulang ditolak
	dunia_scene._pilih_starter(1)
	cek("pilih ulang ditolak (tim tetap 1)", Tim.jumlah() == 1 and int(Progres.starter_id) == 2)

	# ---------- 5. persistensi starter (Simpanan v2)
	Simpanan.terapkan(Simpanan.ambil_state())
	cek("starter direstore dari state", int(Progres.starter_id) == 2 and Tim.jumlah() == 1)

	# ---------- 6. battle scene memakai starter hasil pilihan
	TrainerEngine.set_antrean("")   # pastikan tak ada antrean trainer
	EncounterSystem.reset()
	var paket_b: PackedScene = load("res://game/battle/battle_scene.tscn")
	var battle: Control = paket_b.instantiate()
	root.add_child(battle)
	cek("battle scene: player = starter Orangkici",
		String(battle.player.display_name) == "Orangkici" and int(battle.player.level) == 5,
		"aktual " + String(battle.player.display_name))
	cek("battle scene: wild battle liar tetap jalan", battle.wild != null)

	# ---------- 7. placeholder lama tetap dipakai bila starter belum dipilih
	Progres.reset()
	Tim.reset()
	Nusadex.reset()
	Simpanan.hapus()   # cegah auto-load mengembalikan starter lama
	var battle2: Control = paket_b.instantiate()
	root.add_child(battle2)
	cek("tanpa starter → placeholder anak rimau",
		String(battle2.player.display_name) == "Anak Rimau",
		"aktual " + String(battle2.player.display_name))

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)