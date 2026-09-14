extends SceneTree
## Tes headless EncounterSystem NUSAMON (Fase 3 langkah 2): pool tabel khas +
## pool habitat (habitatPulau × bobot rarity), rol berbobot, peluang per rute,
## antrean battle liar, dan formula kabur speed-based (C-3).
## Jalankan: godot --headless --script game/tests/test_encounter.gd
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


## Mon palsu minimal untuk tes coba_kabur (hanya SPE + tahap stat dibaca).
func mon_spe(spe: int, tahap := 0) -> NusamonInstance:
	var m := NusamonInstance.new()
	m.stats = {"spe": spe}
	m.stats_efektif = {"spe": spe}
	m.stat_stages = {"spe": tahap}
	return m


func _init() -> void:
	print("=== Tes EncounterSystem NUSAMON ===")

	# ---------- bobot rarity (docs/gameplay-depth.md §4)
	cek("bobot common = 60", EncounterSystem.bobot_rarity("common") == 60)
	cek("bobot uncommon = 25", EncounterSystem.bobot_rarity("uncommon") == 25)
	cek("bobot rare = 12", EncounterSystem.bobot_rarity("rare") == 12)
	cek("bobot pseudo_legendary = 3", EncounterSystem.bobot_rarity("pseudo_legendary") == 3)
	cek("legendary = 0 (event)", EncounterSystem.bobot_rarity("legendary") == 0)
	cek("starter = 0 (tidak liar)", EncounterSystem.bobot_rarity("starter") == 0)
	cek("rarity tak dikenal = 0 (gagal aman)", EncounterSystem.bobot_rarity("epik") == 0)

	# ---------- pool dari tabel khas (world.json)
	var db := NusamonData.load_world()
	cek("world.json terbaca", not db.is_empty())
	if db.is_empty():
		quit(1)
		return
	var rute_1 := WorldEngine.lokasi(db, "rute_1")
	var rute_2 := WorldEngine.lokasi(db, "rute_2")
	var pool1 := EncounterSystem.pool_dari_tabel(rute_1)
	var pool2 := EncounterSystem.pool_dari_tabel(rute_2)
	cek("pool rute_1 = 3 entri", pool1.size() == 3, str(pool1.size()))
	cek("pool rute_2 = 3 entri", pool2.size() == 3, str(pool2.size()))
	cek("bobot rute_1 = 40/35/25",
		pool1.size() == 3 and int(pool1[0]["bobot"]) == 40
		and int(pool1[1]["bobot"]) == 35 and int(pool1[2]["bobot"]) == 25)
	cek("spesies rute_1 = monyet/rusa/ayam",
		pool1.size() == 3 and int(pool1[0]["spesies"]) == 23
		and int(pool1[1]["spesies"]) == 22 and int(pool1[2]["spesies"]) == 24)
	cek("level rute_1 2..5", pool1.size() == 3
		and int(pool1[0]["level_min"]) == 2 and int(pool1[2]["level_max"]) == 5)
	var kota := WorldEngine.lokasi(db, "kota_harapan")
	cek("pool kota kosong (tanpa encounter)", EncounterSystem.pool_dari_tabel(kota).is_empty())

	# ---------- pilih_spesies: berbobot & terbatas pool
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260914
	cek("pool kosong → {}", EncounterSystem.pilih_spesies([], rng).is_empty())
	var hitung := {23: 0, 22: 0, 24: 0}
	for i in 1000:
		var e := EncounterSystem.pilih_spesies(pool1, rng)
		var sid := int(e.get("spesies", 0))
		if hitung.has(sid):
			hitung[sid] = int(hitung[sid]) + 1
	cek("1000 rol hanya menghasilkan pool", int(hitung[23]) + int(hitung[22]) + int(hitung[24]) == 1000,
		str(hitung))
	cek("semua spesies pool muncul", int(hitung[23]) > 0 and int(hitung[22]) > 0 and int(hitung[24]) > 0,
		str(hitung))
	cek("bobot menang: monyet(40) > ayam(25)", int(hitung[23]) > int(hitung[24]), str(hitung))

	# ---------- pilih_level
	var entri := {"level_min": 3, "level_max": 5}
	var level_ok := true
	for i in 100:
		var lv := EncounterSystem.pilih_level(entri, rng)
		if lv < 3 or lv > 5:
			level_ok = false
	cek("100 rol level dalam rentang", level_ok)
	cek("rentang terbalik → min", EncounterSystem.pilih_level({"level_min": 5, "level_max": 2}, rng) == 5)

	# ---------- encounter_dari_tabel
	EncounterSystem.reset()
	var ditemukan := 0
	for i in 50:
		var h := EncounterSystem.encounter_dari_tabel(rute_1, rng)
		if h.is_empty():
			continue
		ditemukan += 1
		var sid := int(h.get("spesies", 0))
		if not ((sid == 23 or sid == 22 or sid == 24) and int(h.get("level", 0)) >= 2
				and int(h.get("level", 0)) <= 5):
			ditemukan = -100

	# ---------- pool habitat (habitatPulau × bobot rarity)
	var nusamons := NusamonData.load_nusamons()
	cek("nusamons.json terbaca", not nusamons.is_empty())
	var pool_jawa := EncounterSystem.pool_dari_habitat(nusamons, "Jawa")
	var id_jawa := {}
	for e in pool_jawa:
		id_jawa[int(e["spesies"])] = int(e["bobot"])
	cek("pool Jawa memuat 5 spesies khas (21-25)",
		id_jawa.has(21) and id_jawa.has(22) and id_jawa.has(23)
		and id_jawa.has(24) and id_jawa.has(25), str(id_jawa.keys()))
	cek("starter (Rimau id 1) tidak di pool liar", not id_jawa.has(1))
	cek("semua bobot pool Jawa > 0", pool_jawa.all(func(e: Dictionary) -> bool:
		return int(e["bobot"]) > 0))
	var ada_legendaris := false
	for sp in nusamons.get("nusamons", []):
		var rid := int(sp.get("id", 0))
		if String(sp.get("rarity", "")) == "legendary" and id_jawa.has(rid):
			ada_legendaris = true
	cek("tidak ada legendary di pool liar Jawa", not ada_legendaris)
	var h := EncounterSystem.encounter_dari_habitat(nusamons, "Jawa", rng, [2, 5])
	cek("encounter_dari_habitat valid", not h.is_empty()
		and id_jawa.has(int(h.get("spesies", 0)))
		and int(h.get("level", 0)) >= 2 and int(h.get("level", 0)) <= 5, str(h))

	# ---------- habitat_valid
	cek("monyet (23) berhabitat Jawa", EncounterSystem.habitat_valid(nusamons, "Jawa", 23))
	cek("monyet (23) berhabitat Sumatra", EncounterSystem.habitat_valid(nusamons, "Sumatra", 23))
	cek("beruang (14) TIDAK berhabitat Jawa", not EncounterSystem.habitat_valid(nusamons, "Jawa", 14))
	cek("kakatua (20) TIDAK berhabitat Jawa", not EncounterSystem.habitat_valid(nusamons, "Jawa", 20))
	cek("spesies tak dikenal → tidak valid", not EncounterSystem.habitat_valid(nusamons, "Jawa", 999))

	# ---------- cross-check: tabel khas world.json konsisten habitatPulau per lokasi
	var tabel_konsisten := true
	for lok in db.get("lokasi", []):
		var pl := String(lok.get("pulau", ""))
		for e in lok.get("encounters", []):
			if pl == "" or not EncounterSystem.habitat_valid(nusamons, pl,
					int(e.get("spesies", 0))):
				tabel_konsisten = false
	cek("tabel khas world.json konsisten habitatPulau (semua lokasi)", tabel_konsisten)

	# ---------- peluang per rute
	cek("peluang 1.0 → selalu", EncounterSystem.terjadi({"peluang_encounter": 1.0}, rng))
	cek("peluang 0.0 → tidak pernah", not EncounterSystem.terjadi({"peluang_encounter": 0.0}, rng))
	cek("tanpa field → tidak pernah", not EncounterSystem.terjadi({}, rng))
	rng.seed = 7
	var hit := 0
	for i in 1000:
		if EncounterSystem.terjadi({"peluang_encounter": 0.4}, rng):
			hit += 1
	cek("peluang 0.4: frekuensi masuk akal 30-50%", hit > 300 and hit < 500, str(hit))
	cek("rute_1 punya peluang 0.4", absf(float(rute_1.get("peluang_encounter", 0.0)) - 0.4) < 0.001)
	cek("rute_2 punya peluang 0.45", absf(float(rute_2.get("peluang_encounter", 0.0)) - 0.45) < 0.001)

	# ---------- antrean battle liar (handoff world → battle)
	EncounterSystem.reset()
	cek("antrean awal kosong", EncounterSystem.ambil_antrean().is_empty())
	EncounterSystem.set_antrean(23, 4)
	var a := EncounterSystem.ambil_antrean()
	cek("antrean berisi spesies+level", int(a.get("spesies", 0)) == 23 and int(a.get("level", 0)) == 4)
	cek("antrean dikonsumsi sekali (kosong)", EncounterSystem.ambil_antrean().is_empty())

	# ---------- formula kabur (C-3) — speed-based
	var cepat := mon_spe(100)
	var lambat := mon_spe(10)
	var r := BattleEngine.coba_kabur(cepat, lambat, 1, rng)
	cek("SPE jauh di atas → pasti kabur (f > 255)",
		bool(r["berhasil"]) and int(r["f"]) == 1600 + 30, str(r))
	var sama := BattleEngine.coba_kabur(mon_spe(10), mon_spe(10), 1, rng)
	cek("SPE setara → F = 160 + 30 = 190", int(sama["f"]) == 190, str(sama))
	rng.seed = 99
	var sukses := 0
	for i in 1000:
		if bool(BattleEngine.coba_kabur(mon_spe(10), mon_spe(10), 1, rng)["berhasil"]):
			sukses += 1
	cek("SPE setara: peluang ~74% (190/256)", sukses > 680 and sukses < 800, str(sukses))
	var lemah := BattleEngine.coba_kabur(mon_spe(1), mon_spe(200), 1, rng)
	cek("SPE jauh di bawah → F = 30 (percobaan 1)", int(lemah["f"]) == 30, str(lemah))
	var lemah3 := BattleEngine.coba_kabur(mon_spe(1), mon_spe(200), 3, rng)
	cek("percobaan ke-3 menaikkan F (+60)", int(lemah3["f"]) == 90, str(lemah3))
	cek("percobaan menumpuk menaikkan peluang", int(lemah3["f"]) > int(lemah["f"]))
	var penyebut_nol := BattleEngine.coba_kabur(mon_spe(1), mon_spe(3), 1, rng)
	cek("SPE lawan < 4 → pasti kabur (penyebut 0)",
		bool(penyebut_nol["berhasil"]) and int(penyebut_nol["f"]) == 256)
	var buffed := mon_spe(10, 6)
	var r_buff := BattleEngine.coba_kabur(buffed, mon_spe(10), 1, rng)
	cek("tahap spe +6 memperhitungkan faktor tahap (F = 640 + 30)",
		int(r_buff["f"]) == 670, str(r_buff))

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)
	cek("encounter_dari_tabel valid (50x)", ditemukan == 50, str(ditemukan))
	cek("encounter kota → {}", EncounterSystem.encounter_dari_tabel(kota, rng).is_empty())