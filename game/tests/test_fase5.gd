extends SceneTree
## Tes headless Fase 5 NUSAMON — produksi konten penuh:
##   1. World 6 pulau (28 lokasi, field pulau)
##   2. Gate item (WorldEngine jenis "item") + alur progresi antarpulau
##   3. Gym G3-G8 + Elite Empat (liga) + Juara Nara (data & tim)
##   4. Legendary 1x per save (Progres + Simpanan aditif) + spawn battle
## Jalankan: godot --headless --script game/tests/test_fase5.gd
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
	print("=== Tes Fase 5 NUSAMON ===")
	var dunia := NusamonData.load_world()
	var db := NusamonData.load_trainers()
	var nusamons := NusamonData.load_nusamons()
	cek("data terbaca", not dunia.is_empty() and not db.is_empty() and not nusamons.is_empty())
	if dunia.is_empty() or db.is_empty():
		quit(1)
		return

	# ---------- 1. world 6 pulau
	cek("28 lokasi", dunia.get("lokasi", []).size() == 28, str(dunia.get("lokasi", []).size()))
	cek("7 wilayah (6 pulau + laut)", dunia.get("pulau", []).size() == 7)
	var semua_pulau := true
	var ids := {}
	for l in dunia.get("lokasi", []):
		ids[String(l.get("id", ""))] = l
		if String(l.get("pulau", "")) == "":
			semua_pulau = false
	cek("semua lokasi ber-pulau", semua_pulau)
	for idk in ["laut_nusantara", "pelabuhan_bakau", "muara_kapuas", "pelabuhan_anoa",
			"kota_pura", "pelabuhan_cendana", "kota_puncak", "puncak_salju"]:
		cek("lokasi '%s' ada" % idk, ids.has(idk))

	# ---------- 2. gate item + progresi antarpulau
	var kosong := {"lencana": [], "item": []}
	cek("gate item: tanpa tiket → terkunci",
		not WorldEngine.syarat_terpenuhi({"jenis": "item", "id": "tiket_kapal"}, kosong))
	cek("gate item: dengan tiket → bebas",
		WorldEngine.syarat_terpenuhi({"jenis": "item", "id": "tiket_kapal"},
			{"lencana": [], "item": ["tiket_kapal"]}))
	cek("gate jenis asing gagal aman",
		not WorldEngine.syarat_terpenuhi({"jenis": "galaksi", "id": 99},
			{"lencana": [1, 2, 3, 4, 5, 6, 7, 8]}))
	var pindah := WorldEngine.pindah(dunia, "kota_arunika", "laut_nusantara", kosong)
	cek("Jawa → Laut terkunci tanpa Tiket Kapal", not bool(pindah.get("ok", false)))
	cek("alasan menyebut Tiket Kapal", "Tiket Kapal" in String(pindah.get("alasan", "")))
	pindah = WorldEngine.pindah(dunia, "kota_arunika", "laut_nusantara",
		{"lencana": [], "item": ["tiket_kapal"]})
	cek("Jawa → Laut terbuka dengan Tiket Kapal", bool(pindah.get("ok", false)))
	pindah = WorldEngine.pindah(dunia, "laut_nusantara", "pelabuhan_bakau",
		{"lencana": [], "item": ["tiket_kapal"]})
	cek("Laut → Pelabuhan Bakau bebas (Sumatra)", bool(pindah.get("ok", false)))
	var progres := {"lencana": [], "item": []}
	var tahapan := [
		{"item": "tiket_kapal", "dari": "kota_arunika", "ke": "laut_nusantara"},
		{"item": "", "dari": "laut_nusantara", "ke": "pelabuhan_bakau"},
		{"item": "perahu_selat", "dari": "laut_nusantara", "ke": "muara_kapuas"},
		{"item": "perahu", "dari": "laut_nusantara", "ke": "pelabuhan_anoa"},
		{"item": "perahu_laut_dalam", "dari": "laut_nusantara", "ke": "kota_pura"},
		{"item": "perahu_laut_dalam", "dari": "laut_nusantara", "ke": "pelabuhan_cendana"},
		{"item": "", "dari": "pelabuhan_cendana", "ke": "hutan_cendana"},
		{"item": "", "dari": "hutan_cendana", "ke": "rute_7"},
		{"item": "", "dari": "rute_7", "ke": "kota_puncak"},
		{"item": "", "dari": "kota_puncak", "ke": "puncak_salju"},
	]
	var langkah_ok := true
	for t in tahapan:
		if String(t["item"]) != "" and not progres["item"].has(t["item"]):
			progres["item"].append(t["item"])
		var p := WorldEngine.pindah(dunia, String(t["dari"]), String(t["ke"]), progres)
		if not bool(p.get("ok", false)):
			langkah_ok = false
			print("  gagal: %s → %s (%s)" % [t["dari"], t["ke"], p.get("alasan", "")])
		else:
			progres["lokasi"] = t["ke"]
	cek("alur penuh Jawa → Papua (10 langkah)", langkah_ok)
	cek("tiba di Puncak Salju", String(progres.get("lokasi", "")) == "puncak_salju")
	var tujuan := WorldEngine.daftar_tujuan(dunia, "kota_arunika", kosong)
	var alasan_laut := ""
	for t2 in tujuan:
		if String(t2.get("id", "")) == "laut_nusantara":
			alasan_laut = String(t2.get("alasan", ""))
	cek("UI tujuan menampilkan alasan Tiket Kapal", "Tiket Kapal" in alasan_laut)

	_bagian_3(db, nusamons)


func _bagian_3(db: Dictionary, nusamons: Dictionary) -> void:
	# ---------- 3. gym G3-G8 + liga + juara
	var kota_gym := ["kota_rimba", "kota_toba", "kota_kapuas", "kota_maroso",
		"kota_sabana", "kota_puncak"]
	for i in range(3, 9):
		var gy := TrainerEngine.trainer_di_kota(db, kota_gym[i - 3])
		cek("gym G%d ada di %s" % [i, kota_gym[i - 3]], not gy.is_empty()
			and int(gy.get("gym", {}).get("id", 0)) == i)
		var tim: Array = TrainerEngine.buat_tim(db, String(gy.get("id", "")), nusamons)
		cek("tim gym G%d bisa dibuat (%d mon)" % [i, tim.size()], tim.size() >= 2)
	var urutan_ok := true
	var urut_sebelumnya := 0
	for tid in ["kak_dinda", "pak_nandra", "bu_waja", "kapten_samudra"]:
		var lg := TrainerEngine.cari(db, tid)
		cek("trainer liga '%s' ada" % tid, not lg.is_empty()
			and String(lg.get("jenis", "")) == "liga")
		if int(lg.get("urutan", 0)) <= urut_sebelumnya:
			urutan_ok = false
		urut_sebelumnya = int(lg.get("urutan", 0))
		if TrainerEngine.buat_tim(db, tid, nusamons).is_empty():
			urutan_ok = false
	cek("Elite Empat urutan 1..4 + tim valid", urutan_ok)
	var nara := TrainerEngine.cari(db, "nara")
	cek("Juara Nara ada (jenis juara)", not nara.is_empty()
		and String(nara.get("jenis", "")) == "juara")
	cek("tim Juara Nara = 5 mon", TrainerEngine.buat_tim(db, "nara", nusamons).size() == 5)
	cek("nama tahap Juara sesuai (Rimau Agung)",
		"Rimau Agung" in TrainerEngine.tim_teks(db, "nara", nusamons))
	cek("liga/juara tanpa lencana", TrainerEngine.lencana(db, "nara").is_empty()
		and TrainerEngine.lencana(db, "kak_dinda").is_empty())
	_bagian_4()


func _bagian_4() -> void:
	# ---------- 4. legendary 1x per save
	Progres.reset()
	cek("legendary awal kosong", Progres.legendary_dijumpai.is_empty())
	Progres.tandai_legendary(4)
	Progres.tandai_legendary(4)   # idempoten
	cek("tandai legendary idempoten", Progres.legendary_dijumpai == [4])
	cek("sudah_jumpai_legendary(4)", Progres.sudah_jumpai_legendary(4))
	cek("belum jumpai legendary 6", not Progres.sudah_jumpai_legendary(6))
	Simpanan.hapus()
	Progres.tandai_legendary(5)
	var simpan_ok := Simpanan.simpan()
	Progres.legendary_dijumpai = []
	cek("legendary hilang dari sesi sebelum muat", Progres.legendary_dijumpai.is_empty())
	var muat_ok := simpan_ok and Simpanan.muat()
	cek("simpan+muat legendary", muat_ok and Progres.sudah_jumpai_legendary(5))
	var state := Simpanan.ambil_state()
	state.erase("versi")
	state["progres"] = {"lokasi": "desa_sumberrejo", "lencana": [], "trainer_kalah": [], "starter": 1}
	Simpanan.terapkan(state)
	cek("field legendary aditif (v2 lama tanpa field)", Progres.legendary_dijumpai.is_empty()
		and Progres.starter_id == 1)
	Simpanan.hapus()
	Progres.reset()
	Inventori.reset()
	cek("nama_item Tiket Kapal", Inventori.nama_item("tiket_kapal") == "Tiket Kapal")
	cek("kunci_dimiliki awal kosong", Inventori.kunci_dimiliki().is_empty())
	Inventori.tambah_item("tiket_kapal", 1)
	Inventori.tambah_item("perahu", 1)
	var kunci: Array = Inventori.kunci_dimiliki()
	cek("kunci_dimiliki 2 item", kunci.has("tiket_kapal") and kunci.has("perahu")
		and kunci.size() == 2)
	var legendary_poi := 0
	var tiket_poi := 0
	var poi_paus := {}
	var dunia := NusamonData.load_world()
	for l in dunia.get("lokasi", []):
		for poi in l.get("tempat", []):
			if String(poi.get("aksi", "")) == "legendary":
				legendary_poi += 1
				if int(poi.get("spesies", 0)) == 6:
					poi_paus = poi
			if String(poi.get("aksi", "")) == "tiket":
				tiket_poi += 1
	cek("3 POI legendary", legendary_poi == 3)
	cek("4 POI tiket", tiket_poi == 4)
	cek("Paus Samudra di Palung butuh perahu_laut_dalam",
		String(poi_paus.get("item", "")) == "perahu_laut_dalam"
		and int(poi_paus.get("level", 0)) == 50)
	# antrean legendary → battle scene spawn (Elang Garuda)
	EncounterSystem.set_antrean(4, 50)
	var paket: PackedScene = load("res://game/battle/battle_scene.tscn")
	var scene: Control = paket.instantiate()
	get_root().add_child(scene)
	cek("battle legendary: wild = Elang Garuda (id 4)", scene.wild.id == 4)
	cek("battle legendary: level 50", scene.wild.level == 50)
	cek("battle legendary: bukan mode trainer", not scene.mode_trainer)
	scene.queue_free()
	EncounterSystem.reset()

	print("")
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)
