extends SceneTree
## Tes headless AbilityEngine NUSAMON — 12 ability (docs/gameplay-depth.md §1).
## Jalankan: godot --headless --script game/tests/test_ability.gd
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


func seeded(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func _buat(data: Dictionary, id: int, level := 10) -> NusamonInstance:
	return NusamonInstance.create(
		NusamonData.find_species(data, id), data["detailSpesies"][str(id)], 0, level)


func _init() -> void:
	print("=== Tes AbilityEngine NUSAMON ===")
	var data := NusamonData.load_nusamons()
	var chart := NusamonData.load_type_chart()
	cek("data terbaca", not data.is_empty() and not chart.is_empty())
	if data.is_empty():
		quit(1)
		return
	var cakar_bara := {"id": "cakar_bara", "tipe": "Api", "kategori": "fisik",
		"power": 65, "akurasi": 100, "prioritas": 0}
	var target := _buat(data, 22)  # Rusa (Normal, tanpa ability terkait)

	# ---------- 1. taring_tajam & napas_dalan (HP ≤ 1/3)
	var rimau := _buat(data, 1)
	cek("taring_tajam HP penuh = faktor 1",
		is_equal_approx(AbilityEngine.faktor_setengah(rimau, "fisik"), 1.0))
	rimau.take_damage(rimau.max_hp - int(rimau.max_hp / 3.0))
	cek("taring_tajam fisik HP <= 1/3 = 1.5",
		is_equal_approx(AbilityEngine.faktor_setengah(rimau, "fisik"), 1.5))
	cek("taring_tajam spesial = 1",
		is_equal_approx(AbilityEngine.faktor_setengah(rimau, "spesial"), 1.0))
	var cendra := _buat(data, 5)
	cendra.take_damage(cendra.max_hp - int(cendra.max_hp / 3.0))
	cek("napas_dalam spesial HP <= 1/3 = 1.5",
		is_equal_approx(AbilityEngine.faktor_setengah(cendra, "spesial"), 1.5))
	# integrasi damage: HP rendah (taring_tajam) → damage lebih besar (seed sama)
	var lemah := _buat(data, 1)
	lemah.take_damage(lemah.max_hp - int(lemah.max_hp / 3.0))
	var r0 := BattleEngine.execute_move(_buat(data, 1), target, cakar_bara, chart, seeded(11))
	var r1 := BattleEngine.execute_move(lemah, target, cakar_bara, chart, seeded(11))
	cek("taring_tajam menaikkan damage fisik", int(r1["damage"]) > int(r0["damage"]),
		"normal=" + str(r0["damage"]) + " taring=" + str(r1["damage"]))

	# ---------- 2. mata_elang (akurasi selalu 100%)
	var elang := _buat(data, 4)
	cek("akurasi_selalu elang", AbilityEngine.akurasi_selalu(elang))
	var akurasi_1 := {"id": "x", "tipe": "Normal", "kategori": "fisik",
		"power": 40, "akurasi": 1, "prioritas": 0}
	var pernah_miss := false
	for s in range(1, 8):
		var res := BattleEngine.execute_move(elang, target, akurasi_1, chart, seeded(s))
		if bool(res["missed"]):
			pernah_miss = true
	cek("mata_elang tak pernah meleset (akurasi 1, 7 seed)", not pernah_miss)
	var biasa := _buat(data, 22)
	var n_miss := 0
	for s in range(1, 101):
		var res2 := BattleEngine.execute_move(biasa, target, akurasi_1, chart, seeded(s))
		if bool(res2["missed"]):
			n_miss += 1
	cek("tanpa mata_elang akurasi 1 → mayoritas meleset", n_miss > 80, "miss=" + str(n_miss))

	# ---------- 3. kulit_tebal (damage fisik −10%)
	var paus := _buat(data, 6)
	cek("faktor kulit_tebal paus = 0.9",
		is_equal_approx(AbilityEngine.faktor_kulit_tebal(paus), 0.9))
	cek("faktor non-kulit = 1", is_equal_approx(AbilityEngine.faktor_kulit_tebal(rimau), 1.0))
	var r2 := BattleEngine.execute_move(_buat(data, 1), paus, cakar_bara, chart, seeded(11))
	cek("damage fisik ke paus tetap dihitung (x0.9)", int(r2["damage"]) > 0)

	# ---------- 4. refleks_kilat (10% menghindar)
	var lumba := _buat(data, 17)
	var n_hindar := 0
	var rng := seeded(7)
	for i in 1000:
		if AbilityEngine.refleks_hindar(lumba, rng):
			n_hindar += 1
	cek("refleks_kilat ~10%", n_hindar > 50 and n_hindar < 150, "aktual " + str(n_hindar))
	cek("rimau tanpa refleks tak menghindar", not AbilityEngine.refleks_hindar(rimau, seeded(3)))

	# ---------- 5. racun_alami / serbuk_sari / madu_manis (sentuhan fisik 30%)
	var ular := _buat(data, 21)
	var n_racun := 0
	for i in 200:
		var p := _buat(data, 22)
		if AbilityEngine.sentuh_fisik(p, ular, seeded(100 + i)) != "":
			n_racun += 1
	cek("racun_alami ~30%", n_racun > 40 and n_racun < 80, "aktual " + str(n_racun))
	var sudah := _buat(data, 22)
	sudah.status = "luka_bakar"
	cek("penyerang berstatus → tak terkena lagi",
		AbilityEngine.sentuh_fisik(sudah, ular, seeded(1)) == "")
	var kupu := _buat(data, 25)
	var tertidur: NusamonInstance = null
	for s in range(1, 51):
		var p2 := _buat(data, 22)
		if AbilityEngine.sentuh_fisik(p2, kupu, seeded(s)) != "":
			tertidur = p2
			break
	cek("serbuk_sari bisa picu tidur", tertidur != null)
	if tertidur != null:
		cek("tidur berdurasi 2-4 giliran", tertidur.status_turn >= 2 and tertidur.status_turn <= 4)
	var beruang := _buat(data, 14)
	var terpikat_found := false
	for s in range(1, 51):
		var p3 := _buat(data, 22)
		if AbilityEngine.sentuh_fisik(p3, beruang, seeded(s)) != "":
			terpikat_found = p3.status == "terpikat"
			break
	cek("madu_manis bisa picu terpikat", terpikat_found)

	# ---------- 6. pelindung_karang & tiruan_suara (saat masuk battle)
	var penyu := _buat(data, 3)
	var lawan1 := _buat(data, 1)
	var pesan := AbilityEngine.masuk_battle(penyu, lawan1)
	cek("pelindung_karang def +1",
		int(penyu.stat_stages["def"]) == 1 and pesan.contains("Pelindung Karang"))
	var kakatua := _buat(data, 20)
	var lawan2 := _buat(data, 22)
	var pesan2 := AbilityEngine.masuk_battle(kakatua, lawan2)
	cek("tiruan_suara atk lawan -1",
		int(lawan2.stat_stages["atk"]) == -1 and pesan2.contains("Tiruan Suara"))
	var paus2 := _buat(data, 6)
	cek("ability lain tanpa efek masuk", AbilityEngine.masuk_battle(paus2, lawan2) == "")

	# ---------- 7. panen_subur (pulih 12.5% per giliran saat HP <= 1/3)
	var orang := _buat(data, 2)
	cek("panen saat HP penuh = tanpa pesan", AbilityEngine.akhir_giliran(orang) == "")
	orang.take_damage(orang.max_hp - int(orang.max_hp / 3.0))
	var hp_sebelum := orang.current_hp
	var pesan3 := AbilityEngine.akhir_giliran(orang)
	var pulih := maxi(1, int(floor(float(orang.max_hp) * AbilityEngine.PEMULIHAN_PANEN)))
	cek("panen memulihkan max/8 saat HP <= 1/3",
		orang.current_hp == hp_sebelum + pulih and pesan3.contains("Panen Subur"),
		"pesan=" + pesan3)

	# ---------- 8. cengkeraman_kuat & konstanta
	cek("cengkeraman_kuat gurita terkunci", AbilityEngine.lawan_terkunci("cengkeraman_kuat"))
	cek("ability lain tidak mengunci", not AbilityEngine.lawan_terkunci("refleks_kilat"))
	cek("PELUANG_TERPIKAT_GAGAL = 0.5",
		is_equal_approx(AbilityEngine.PELUANG_TERPIKAT_GAGAL, 0.5))

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)