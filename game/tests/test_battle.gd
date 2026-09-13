extends SceneTree
## Tes headless prototipe battle NUSAMON.
## Jalankan dari root repo:
##   godot --headless --script game/tests/test_battle.gd
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
	print("=== Tes Prototipe Battle NUSAMON ===")
	var data := NusamonData.load_nusamons()
	var chart := NusamonData.load_type_chart()
	var moves := NusamonData.load_moves()

	cek("nusamons.json terbaca", not data.is_empty())
	cek("type-chart.json terbaca", not chart.is_empty())
	cek("moves.json terbaca", not moves.is_empty())
	if data.is_empty() or chart.is_empty() or moves.is_empty():
		print("Data gagal dimuat — tes dihentikan.")
		quit(1)
		return

	# ---------- 1. efektivitas tipe
	cek("Air vs Api = 2", NusamonData.effectiveness(chart, "Air", "Api") == 2.0)
	cek("Tanah vs Udara = 0 (kebal)", NusamonData.effectiveness(chart, "Tanah", "Udara") == 0.0)
	cek("Listrik vs Tanah = 0 (kebal)", NusamonData.effectiveness(chart, "Listrik", "Tanah") == 0.0)
	cek("Racun vs Baja = 0 (kebal)", NusamonData.effectiveness(chart, "Racun", "Baja") == 0.0)
	cek("Api vs Daun/Udara = 2.0 (2 x 1)",
		is_equal_approx(NusamonData.effectiveness_multi(chart, "Api", ["Daun", "Udara"]), 2.0))

	# ---------- 2. skala stat evolusi
	var rimau := NusamonData.find_species(data, 1)
	cek("spesies Rimau ditemukan", not rimau.is_empty())
	var stat_anak := NusamonData.stats_for_stage(rimau, 0)
	cek("Anak Rimau hp = 48", int(stat_anak["hp"]) == 48, "aktual " + str(stat_anak["hp"]))
	cek("Anak Rimau atk = 72", int(stat_anak["atk"]) == 72)
	var stat_final := NusamonData.stats_for_stage(rimau, 2)
	cek("Rimau Agung atk = 120", int(stat_final["atk"]) == 120)

	# ---------- 3. instans battle
	var detail_rimau: Dictionary = data["detailSpesies"]["1"]
	var a := NusamonInstance.create(rimau, detail_rimau, 0, 5)
	cek("Anak Rimau Lv5 dibuat", a.display_name == "Anak Rimau")
	cek("tipe = [Api]", a.types == ["Api"])
	cek("max_hp Lv5 = 19", a.max_hp == 19, "aktual " + str(a.max_hp))
	cek("atk Lv5 = 12", int(a.stats["atk"]) == 12, "aktual " + str(a.stats["atk"]))
	cek("move lv1 tersedia", a.move_ids.has("cakaran"))
	cek("move lv30 belum tersedia", not a.move_ids.has("napas_panas"))

	# ---------- 4. damage: STAB & efektivitas (deterministik via seed)
	var cakaran := {"id": "cakaran", "tipe": "Normal", "kategori": "fisik", "power": 40, "akurasi": 100, "prioritas": 0}
	var b := NusamonInstance.create(rimau, detail_rimau, 0, 5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var res_cakar := BattleEngine.execute_move(a, b, cakaran, chart, rng)
	cek("damage cakaran > 0", int(res_cakar["damage"]) > 0)
	cek("tanpa STAB (move Normal, pengguna Api)", not bool(res_cakar["stab"]))

	var cakar_bara := {"id": "cakar_bara", "tipe": "Api", "kategori": "fisik", "power": 65, "akurasi": 100, "prioritas": 0}
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 7
	var res_bara := BattleEngine.execute_move(a, b, cakar_bara, chart, rng2)
	cek("STAB aktif (move Api, pengguna Api)", bool(res_bara["stab"]))

	# Api vs Ulat Daun (Daun) harus lebih besar daripada vs Rusa (Normal), seed sama
	var ulat := NusamonData.find_species(data, 25)
	var rusa := NusamonData.find_species(data, 22)
	var target_daun := NusamonInstance.create(ulat, data["detailSpesies"]["25"], 0, 10)
	var target_netral := NusamonInstance.create(rusa, data["detailSpesies"]["22"], 0, 10)
	var rng3 := RandomNumberGenerator.new()
	rng3.seed = 7
	var res_daun := BattleEngine.execute_move(a, target_daun, cakar_bara, chart, rng3)
	var rng4 := RandomNumberGenerator.new()
	rng4.seed = 7
	var res_netral := BattleEngine.execute_move(a, target_netral, cakar_bara, chart, rng4)
	cek("efek 2x vs Daun", is_equal_approx(float(res_daun["eff"]), 2.0))
	cek("damage vs Daun > damage vs Normal",
		int(res_daun["damage"]) > int(res_netral["damage"]),
		"daun=" + str(res_daun["damage"]) + " netral=" + str(res_netral["damage"]))

	# kebal: Tanah vs Kakatua Muda (Udara/Normal) = 0 damage
	var kakatua := NusamonData.find_species(data, 20)
	var target_udara := NusamonInstance.create(kakatua, data["detailSpesies"]["20"], 0, 10)
	var gempa := {"id": "gempa_kecil", "tipe": "Tanah", "kategori": "fisik", "power": 55, "akurasi": 100, "prioritas": 0}
	var rng5 := RandomNumberGenerator.new()
	rng5.seed = 1
	var res_kebal := BattleEngine.execute_move(a, target_udara, gempa, chart, rng5)
	cek("Tanah vs Udara/Normal = 0 damage", int(res_kebal["damage"]) == 0)

	# ---------- 5. luka bakar memotong ATK fisik
	var terbakar := NusamonInstance.create(rimau, detail_rimau, 0, 5)
	terbakar.status = "luka_bakar"
	var rng6 := RandomNumberGenerator.new()
	rng6.seed = 9
	var res_bakar := BattleEngine.execute_move(terbakar, target_netral, cakar_bara, chart, rng6)
	cek("luka bakar mengurangi damage fisik", int(res_bakar["damage"]) < int(res_netral["damage"]))

	# ---------- 6. urutan giliran
	var move_biasa := {"prioritas": 0}
	var move_prioritas := {"prioritas": 1}
	var urut := BattleEngine.urutan_giliran(a, move_prioritas, target_netral, move_biasa)
	cek("prioritas menang atas speed", urut[0] == a)
	var monyet := NusamonData.find_species(data, 23)
	var m := NusamonInstance.create(monyet, data["detailSpesies"]["23"], 0, 10)
	var u := BattleEngine.urutan_giliran(m, move_biasa, target_netral, move_biasa)
	cek("SPE tinggi menang", u[0] == m)

	# ---------- 7. status: racun di akhir giliran
	var teracuni := NusamonInstance.create(rimau, detail_rimau, 0, 5)
	BattleEngine.terapkan_status(teracuni, "racun", RandomNumberGenerator.new())
	var hp_awal := teracuni.current_hp
	var pesan := BattleEngine.akhir_giliran_status(teracuni, RandomNumberGenerator.new())
	var d_harus := maxi(1, int(floor(float(teracuni.max_hp) / 8.0)))
	cek("racun memotong HP", teracuni.current_hp == hp_awal - d_harus, pesan)

	# ---------- 8. pingsan
	teracuni.take_damage(9999)
	cek("take_damage(9999) -> pingsan", teracuni.is_fainted() and teracuni.current_hp == 0)

	# ---------- 9. tahap stat (buff/debuff) & PP & samaran
	cek("faktor_tahap(0) = 1", is_equal_approx(BattleEngine.faktor_tahap(0), 1.0))
	cek("faktor_tahap(1) = 1.5", is_equal_approx(BattleEngine.faktor_tahap(1), 1.5))
	cek("faktor_tahap(-1) = 2/3", is_equal_approx(BattleEngine.faktor_tahap(-1), 2.0 / 3.0))
	var buff := NusamonInstance.create(rimau, detail_rimau, 0, 5)
	cek("tahap awal 0", buff.ubah_tahap_stat("atk", 2) == 2)
	for i in 8:
		buff.ubah_tahap_stat("atk", 1)
	cek("tahap atk clamp di +6", int(buff.stat_stages["atk"]) == 6)

	# buff atk → damage lebih besar (seed sama)
	var p0 := NusamonInstance.create(rimau, detail_rimau, 0, 5)
	var pg := NusamonInstance.create(rimau, detail_rimau, 0, 5)
	pg.ubah_tahap_stat("atk", 1)
	var t_def := NusamonInstance.create(rusa, data["detailSpesies"]["22"], 0, 10)
	var rng7 := RandomNumberGenerator.new()
	rng7.seed = 11
	var r_nobuff := BattleEngine.execute_move(p0, t_def, cakar_bara, chart, rng7)
	var rng8 := RandomNumberGenerator.new()
	rng8.seed = 11
	var r_buff := BattleEngine.execute_move(pg, t_def, cakar_bara, chart, rng8)
	cek("buff atk menaikkan damage", int(r_buff["damage"]) > int(r_nobuff["damage"]),
		"buff=" + str(r_buff["damage"]) + " dasar=" + str(r_nobuff["damage"]))

	# debuff def target → damage yang diterima lebih besar
	var t_def_minus := NusamonInstance.create(rusa, data["detailSpesies"]["22"], 0, 10)
	t_def_minus.ubah_tahap_stat("def", -1)
	var rng9 := RandomNumberGenerator.new()
	rng9.seed = 11
	var r_defminus := BattleEngine.execute_move(p0, t_def_minus, cakar_bara, chart, rng9)
	cek("debuff def target menaikkan damage",
		int(r_defminus["damage"]) > int(r_nobuff["damage"]))

	# tahap spe mengubah urutan giliran: rusa lv10 spe 16 (+2 → 24) > monyet 18
	var kura := NusamonInstance.create(rusa, data["detailSpesies"]["22"], 0, 10)
	kura.ubah_tahap_stat("spe", 2)
	var u2 := BattleEngine.urutan_giliran(m, move_biasa, kura, move_biasa)
	cek("tahap spe mengubah urutan", u2[0] == kura)

	# PP
	var anak2 := NusamonInstance.create(rimau, detail_rimau, 0, 5)
	cek("PP cakaran = 35", anak2.pp_move("cakaran") == 35, "aktual " + str(anak2.pp_move("cakaran")))
	cek("pakai_move mengurangi PP", anak2.pakai_move("cakaran") and anak2.pp_move("cakaran") == 34)
	anak2.move_pp["cakaran"] = 0
	cek("pakai_move false saat PP 0", not anak2.pakai_move("cakaran"))
	cek("SAMARAN power 50", int(BattleEngine.SAMARAN["power"]) == 50)

	# C-2: kelumpuhan tidak lagi di-rol di fase akhir giliran
	var lumpuh := NusamonInstance.create(rimau, detail_rimau, 0, 5)
	lumpuh.status = "kelumpuhan"
	cek("kelumpuhan tanpa pesan di fase akhir",
		BattleEngine.akhir_giliran_status(lumpuh, RandomNumberGenerator.new()) == "")

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)