extends SceneTree
## Tes headless peta dunia NUSAMON (Fase 3 langkah 1): data world.json,
## traversal WorldEngine, gate lencana, tabel encounter, store Progres.
## Jalankan: godot --headless --script game/tests/test_world.gd
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


## Koneksi a->b ada di data (untuk cek simetri).
func terhubung(db: Dictionary, a: String, b: String) -> bool:
	for k in db.get("koneksi", []):
		if String(k.get("dari", "")) == a and String(k.get("ke", "")) == b:
			return true
	return false


func _init() -> void:
	print("=== Tes Peta Dunia NUSAMON ===")
	var db := NusamonData.load_world()
	cek("world.json terbaca", not db.is_empty())
	if db.is_empty():
		quit(1)
		return

	# ---------- struktur data
	var lokasi: Array = db.get("lokasi", [])
	cek("5 lokasi Jawa MVP", lokasi.size() == 5, "aktual " + str(lokasi.size()))
	cek("lokasi_awal = desa_sumberrejo", String(db.get("lokasi_awal", "")) == "desa_sumberrejo")
	var id_harapan := ["desa_sumberrejo", "rute_1", "kota_harapan", "rute_2", "kota_arunika"]
	var ids: Array = []
	for l in lokasi:
		ids.append(String(l.get("id", "")))
	cek("id lokasi lengkap & berurutan", ids == id_harapan, str(ids))
	var koneksi: Array = db.get("koneksi", [])
	cek("8 koneksi (4 pasang dua arah)", koneksi.size() == 8, "aktual " + str(koneksi.size()))

	# ---------- lookup lokasi
	var desa := WorldEngine.lokasi(db, "desa_sumberrejo")
	cek("desa ditemukan", not desa.is_empty())
	cek("nama desa benar", String(desa.get("nama", "")) == "Desa Sumberrejo")
	cek("jenis desa = desa", String(desa.get("jenis", "")) == "desa")
	cek("lokasi tak dikenal -> {}", WorldEngine.lokasi(db, "kuta_bali").is_empty())

	# ---------- koneksi simetris + rujukan valid
	var semua_simetris := true
	var rujukan_valid := true
	for k in koneksi:
		var a := String(k.get("dari", ""))
		var b := String(k.get("ke", ""))
		if not (ids.has(a) and ids.has(b)):
			rujukan_valid = false
		if not terhubung(db, b, a):
			semua_simetris = false
	cek("semua koneksi rujuk lokasi valid", rujukan_valid)
	cek("semua koneksi simetris", semua_simetris)

	# ---------- traversal: jalur bahagia
	cek("desa -> rute_1 ok",
		bool(WorldEngine.pindah(db, "desa_sumberrejo", "rute_1", {}).get("ok", false)))
	cek("rute_1 -> kota_harapan ok",
		bool(WorldEngine.pindah(db, "rute_1", "kota_harapan", {}).get("ok", false)))
	cek("rute_2 -> kota_arunika ok",
		bool(WorldEngine.pindah(db, "rute_2", "kota_arunika", {}).get("ok", false)))
	cek("kota_arunika -> rute_2 ok (dua arah)",
		bool(WorldEngine.pindah(db, "kota_arunika", "rute_2", {}).get("ok", false)))
	cek("rute_1 -> desa ok (mundur)",
		bool(WorldEngine.pindah(db, "rute_1", "desa_sumberrejo", {}).get("ok", false)))

	# ---------- gate lencana di kota_harapan -> rute_2
	var r := WorldEngine.pindah(db, "kota_harapan", "rute_2", {})
	cek("rute_2 terkunci tanpa lencana", not bool(r.get("ok", false)))
	cek("alasan menyebut Lencana", String(r.get("alasan", "")).contains("Lencana"),
		String(r.get("alasan", "")))
	cek("jalan pulang rute_2 -> kota_harapan bebas tanpa lencana",
		bool(WorldEngine.pindah(db, "rute_2", "kota_harapan", {}).get("ok", false)))
	r = WorldEngine.pindah(db, "kota_harapan", "rute_2", {"lencana": [1]})
	cek("rute_2 terbuka dengan Lencana G1", bool(r.get("ok", false)))
	cek("hasil pindah membawa data tujuan",
		String(r.get("lokasi", {}).get("id", "")) == "rute_2")
	r = WorldEngine.pindah(db, "kota_harapan", "rute_2", {"lencana": [2, 3]})
	cek("lencana salah tetap terkunci", not bool(r.get("ok", false)))

	# ---------- kasus gagal traversal
	cek("desa -> kota_harapan gagal (bukan tetangga)",
		not bool(WorldEngine.pindah(db, "desa_sumberrejo", "kota_harapan", {}).get("ok", false)))
	cek("asal tak dikenal gagal",
		not bool(WorldEngine.pindah(db, "atlantis", "rute_1", {}).get("ok", false)))
	cek("tujuan tak dikenal gagal",
		not bool(WorldEngine.pindah(db, "rute_1", "atlantis", {}).get("ok", false)))
	cek("alasan tak terhubung menjelaskan",
		String(WorldEngine.alasan_terkunci(db, "desa_sumberrejo", "kota_arunika", {})).contains("tidak terhubung"))

	# ---------- daftar_tujuan untuk UI
	var tg := WorldEngine.daftar_tujuan(db, "desa_sumberrejo", {})
	cek("desa punya 1 tujuan", tg.size() == 1)
	cek("tujuan desa = rute_1", tg.size() == 1 and String(tg[0].get("id", "")) == "rute_1")
	cek("tujuan desa tidak terkunci", tg.size() == 1 and not bool(tg[0].get("terkunci", true)))
	var tg_kota := WorldEngine.daftar_tujuan(db, "kota_harapan", {})
	var entri_rute2 := {}
	for t in tg_kota:
		if String(t.get("id", "")) == "rute_2":
			entri_rute2 = t
	cek("kota_harapan punya 2 tujuan", tg_kota.size() == 2)
	cek("rute_2 tertanda terkunci di daftar", bool(entri_rute2.get("terkunci", false)))
	var tg_kota2 := WorldEngine.daftar_tujuan(db, "kota_harapan", {"lencana": [1]})
	var entri_rute2b := {}
	for t in tg_kota2:
		if String(t.get("id", "")) == "rute_2":
			entri_rute2b = t
	cek("rute_2 terbuka di daftar saat punya lencana", not bool(entri_rute2b.get("terkunci", true)))

	# ---------- syarat gate: jenis tak dikenal gagal aman
	cek("gate tanpa syarat bebas", WorldEngine.syarat_terpenuhi({}, {}))
	cek("gate jenis tak dikenal terkunci", not WorldEngine.syarat_terpenuhi({"jenis": "sihir"}, {}))

	# ---------- graf terhubung (BFS dari lokasi awal)
	var dicap := {"desa_sumberrejo": true}
	var antrian: Array = ["desa_sumberrejo"]
	while not antrian.is_empty():
		var cur: String = antrian.pop_front()
		for t in WorldEngine.daftar_tujuan(db, cur, {"lencana": [1, 2, 3, 4, 5, 6, 7, 8]}):
			var nid := String(t.get("id", ""))
			if not dicap.has(nid):
				dicap[nid] = true
				antrian.append(nid)
	cek("graf terhubung: 5 lokasi dicapai dari awal", dicap.size() == 5, str(dicap.keys()))

	# ---------- data encounter (langkah 2 memakai ini)
	var nusamons := NusamonData.load_nusamons()
	cek("nusamons.json terbaca untuk cek encounter", not nusamons.is_empty())
	var encounter_ok := true
	var spesies_valid := true
	var kota_tanpa_encounter := true
	for l in lokasi:
		var enc: Array = l.get("encounters", [])
		var jenis := String(l.get("jenis", ""))
		if jenis == "rute" and enc.is_empty():
			encounter_ok = false
		if jenis != "rute" and not enc.is_empty():
			kota_tanpa_encounter = false
		for e in enc:
			if NusamonData.find_species(nusamons, int(e.get("spesies", 0))).is_empty():
				spesies_valid = false
			if float(e.get("bobot", 0)) <= 0.0:
				encounter_ok = false
			if int(e.get("level_min", 0)) > int(e.get("level_max", 0)):
				encounter_ok = false
	cek("rute punya tabel encounter", encounter_ok)
	cek("semua spesies encounter ada di nusamons.json", spesies_valid)
	cek("kota/desa tanpa encounter", kota_tanpa_encounter)

	# ---------- store Progres
	Progres.reset()
	cek("progres awal tanpa lencana", not Progres.punya_lencana(1))
	cek("jumlah lencana awal = 0", Progres.jumlah_lencana() == 0)
	Progres.lokasi = "desa_sumberrejo"
	Progres.tambah_lencana(1)
	cek("lencana 1 didapat", Progres.punya_lencana(1))
	cek("jumlah lencana = 1", Progres.jumlah_lencana() == 1)
	Progres.tambah_lencana(1)
	cek("lencana idempoten (tidak duplikat)", Progres.jumlah_lencana() == 1)
	cek("lencana membuka gate via WorldEngine",
		bool(WorldEngine.pindah(db, "kota_harapan", "rute_2", {"lencana": Progres.lencana}).get("ok", false)))
	Progres.reset()
	cek("reset menghapus lencana & lokasi", Progres.lencana.is_empty() and Progres.lokasi == "")

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)