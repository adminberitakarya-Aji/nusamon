extends SceneTree
## Tes headless rival NUSAMON (Fase 4 langkah 3): data rival, counter-starter,
## battle vs Raka (menang → hadiah, TANPA lencana), satu kali saja.
## Jalankan: godot --headless --script game/tests/test_rival.gd
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
	print("=== Tes Rival NUSAMON ===")
	var db := NusamonData.load_trainers()
	var nusamons := NusamonData.load_nusamons()
	var dunia := NusamonData.load_world()
	cek("trainers.json terbaca", not db.is_empty())
	if db.is_empty() or nusamons.is_empty() or dunia.is_empty():
		quit(1)
		return

	# ---------- 1. data rival (data-driven)
	var raka := TrainerEngine.cari(db, "rival_raka")
	cek("rival Raka ditemukan", not raka.is_empty())
	cek("jenis = rival", String(raka.get("jenis", "")) == "rival")
	cek("rival tanpa gym", raka.get("gym") == null)
	cek("rival tanpa lencana", raka.get("lencana") == null)
	cek("dialog rival terisi",
		String(raka.get("dialog", {}).get("intro", "")) != ""
		and String(raka.get("dialog", {}).get("menang_pemain", "")) != "")
	cek("hadiah rival = Rp 500", int(raka.get("hadiah_uang", 0)) == 500)
	var tim_data: Array = raka.get("tim", [])
	cek("tim rival: counter_starter (tanpa spesies tetap)", tim_data.size() == 1
		and bool(tim_data[0].get("counter_starter", false))
		and int(tim_data[0].get("spesies", 0)) == 0
		and int(tim_data[0].get("level", 0)) == 6)
	# POI rival di Rute 1
	var rute1 := WorldEngine.lokasi(dunia, "rute_1")
	var poi_rival := {}
	for t in rute1.get("tempat", []):
		if String(t.get("id", "")) == "rival_raka":
			poi_rival = t
	cek("POI rival di rute_1 dengan aksi rival",
		not poi_rival.is_empty() and String(poi_rival.get("aksi", "")) == "rival")

	# ---------- 2. counter-starter (konvensi genre)
	cek("starter Api (Rimau) → rival Penyuci (Air)", TrainerEngine.starter_lawan(1) == 3)
	cek("starter Daun (Orangutan) → rival Rimau (Api)", TrainerEngine.starter_lawan(2) == 1)
	cek("starter Air (Penyu) → rival Orangkici (Daun)", TrainerEngine.starter_lawan(3) == 2)
	cek("starter belum dipilih → fallback Penyuci", TrainerEngine.starter_lawan(0) == 3)
	Progres.reset()
	Progres.pilih_starter(2)   # pemain Orangkici (Daun) → rival Anak Rimau (Api)
	var tim_rival := TrainerEngine.buat_tim(db, "rival_raka", nusamons)
	cek("tim rival = 1 mon", tim_rival.size() == 1)
	cek("rival: counter Anak Rimau Lv.6 (unggul tipe atas Daun)",
		tim_rival.size() == 1 and String(tim_rival[0].display_name) == "Anak Rimau"
		and int(tim_rival[0].level) == 6)
	Progres.reset()
	Progres.pilih_starter(3)
	cek("counter penyu → Orangkici (Daun)",
		TrainerEngine.buat_tim(db, "rival_raka", nusamons)[0].display_name == "Orangkici")
	Progres.reset()
	Progres.pilih_starter(1)
	cek("counter rimau → Penyuci (Air)",
		TrainerEngine.buat_tim(db, "rival_raka", nusamons)[0].display_name == "Penyuci")

	# ---------- 3. battle vs rival → menang: hadiah TANPA lencana, sekali saja
	Inventori.reset()
	Tim.reset()
	Nusadex.reset()
	Simpanan.hapus()
	Progres.reset()
	Progres.pilih_starter(2)
	Progres.lokasi = "rute_1"
	TrainerEngine.set_antrean("rival_raka")
	var paket: PackedScene = load("res://game/battle/battle_scene.tscn")
	var scene: Control = paket.instantiate()
	root.add_child(scene)
	cek("scene: mode trainer (rival)", scene.mode_trainer
		and String(scene.trainer_data.get("id", "")) == "rival_raka")
	cek("scene: lawan = Anak Rimau (counter starter Orangkici)",
		String(scene.wild.display_name) == "Anak Rimau")
	var lencana_sebelum := Progres.jumlah_lencana()
	var uang_sebelum := int(Inventori.uang)
	scene.wild.take_damage(9999)
	scene._akhir_battle(true)
	cek("menang vs rival → battle selesai",
		scene.log_label.text.contains("Battle selesai (menang vs trainer)"))
	cek("hadiah Rp 500 masuk", int(Inventori.uang) == uang_sebelum + 500,
		"aktual " + str(Inventori.uang))
	cek("TIDAK mendapat lencana (jumlah lencana tetap)",
		Progres.jumlah_lencana() == lencana_sebelum,
		"aktual " + str(Progres.jumlah_lencana()))
	cek("tidak ada lencana id 0 (guard rival)", not Progres.lencana.has(0))
	cek("rival tercatat kalah", Progres.sudah_kalah_trainer("rival_raka"))

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)