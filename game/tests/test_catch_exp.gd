extends SceneTree
## Tes headless: sistem tangkap (CatchSystem) + EXP/evolusi (ExpSystem).
## Jalankan: godot --headless --script game/tests/test_catch_exp.gd

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
	print("=== Tes Tangkap & EXP NUSAMON ===")
	var data := NusamonData.load_nusamons()
	var chart := NusamonData.load_type_chart()
	cek("data terbaca", not data.is_empty() and not chart.is_empty())
	if data.is_empty():
		quit(1)
		return

	# ---------- CatchSystem: peluang dasar a
	var rusa := NusamonData.find_species(data, 22)
	var detail_rusa: Dictionary = data["detailSpesies"]["22"]
	var target := NusamonInstance.create(rusa, detail_rusa, 0, 10)
	# Rusa Muda Lv10: hp base ceili(60*0.65)=39 → HP = floor(2*39*10/100)+10+10 = 27
	cek("target HP = 27", target.max_hp == 27, "aktual " + str(target.max_hp))
	var rate := int(detail_rusa.get("catchRate", 190))

	# a (HP penuh, amukan) = (81-54)*190/81 = 63.33
	var a_penuh := CatchSystem.catch_a(target, rate, "amukan")
	cek("a HP penuh ~63.3", a_penuh > 63.0 and a_penuh < 64.0, "aktual " + str(a_penuh))

	# a (HP 1, amukan super) = (81-2)*190*2/81 = 370 → >= 255 pasti
	target.take_damage(target.max_hp - 1)
	var a_past := CatchSystem.catch_a(target, rate, "amukan_super")
	cek("a HP rendah + super = pasti (>=255)", a_past >= 255.0, "aktual " + str(a_past))
	var r_past := CatchSystem.attempt_catch(target, rate, "amukan_super", RandomNumberGenerator.new())
	cek("tangkap pasti", r_past["catch"] and r_past["guaranteed"])

	# bonus status: tidur menggandakan a
	var tidur := NusamonInstance.create(rusa, detail_rusa, 0, 10)
	BattleEngine.terapkan_status(tidur, "tidur", RandomNumberGenerator.new())
	var a_biasa := CatchSystem.catch_a(tidur, rate, "amukan")
	var a_tidur := CatchSystem.catch_a(tidur, rate, "amukan")
	cek("status tidur x2", is_equal_approx(a_tidur, a_biasa * 2.0))

	# attempt dengan seed: hasil deterministik & konsisten
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var r1 := CatchSystem.attempt_catch(tidur, rate, "amukan", rng)
	cek("shakes dalam jangkauan 0-4",
		r1["shakes"] >= 0 and r1["shakes"] <= 4, "aktual " + str(r1["shakes"]))
	cek("konsistensi catch==shakes", r1["catch"] == (r1["shakes"] == 4))

	# ---------- ExpSystem: kurva L^3
	cek("total_exp(5) = 125", ExpSystem.total_exp(5) == 125)
	cek("total_exp(10) = 1000", ExpSystem.total_exp(10) == 1000)
	cek("total_exp(100) = 1.000.000", ExpSystem.total_exp(100) == 1000000)

	# gain wild: base 55, lawan lv 2 → floor(55*2/7) = 15
	cek("exp_gain wild = 15", ExpSystem.exp_gain(55, 2) == 15)
	# gain trainer: floor(15*1.5) = 22
	cek("exp_gain trainer = 22", ExpSystem.exp_gain(55, 2, true) == 22)

	# ---------- naik level: anak rimau lv5, +91 EXP → lv6 (125+91=216=6^3)
	var rimau := NusamonData.find_species(data, 1)
	var detail_rimau: Dictionary = data["detailSpesies"]["1"]
	var anak := NusamonInstance.create(rimau, detail_rimau, 0, 5)
	cek("exp awal lv5 = 125", anak.exp_total == 125)
	var res := ExpSystem.add_exp(anak, rimau, detail_rimau, 91)
	cek("naik 1 level", res["levels_gained"] == 1 and anak.level == 6)
	cek("tanpa evolusi di lv6", res["evolution"] == null)

	# ---------- evolusi: capai lv16 (16^3 = 4096; dari lv5 perlu 3971)
	var res2 := ExpSystem.add_exp(anak, rimau, detail_rimau, 3971)
	cek("naik ke lv16", anak.level == 16, "aktual " + str(anak.level))
	cek("evolusi terpicu", res2["evolution"] != null)
	cek("jadi Rimau Muda", anak.display_name == "Rimau Muda" and anak.stage_index == 1)
	cek("tipe tetap Api", anak.types == ["Api"])
	# Rimau Muda lv16: hp base 64 → floor(2*64*16/100)+16+10 = 20+26 = 46
	cek("HP baru = 46", anak.max_hp == 46, "aktual " + str(anak.max_hp))
	cek("move lv13 (cakar_bara) tersedia", anak.move_ids.has("cakar_bara"))
	cek("move lv30 (napas_panas) belum", not anak.move_ids.has("napas_panas"))

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)