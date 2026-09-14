extends SceneTree
## Tes headless TrainerEngine NUSAMON (Fase 3 langkah 3): data trainers.json,
## lookup trainer/gym, pembuatan tim NusamonInstance, lencana, konsistensi
## lintas-data (kota & gate lencana di world.json).
## Jalankan: godot --headless --script game/tests/test_trainer.gd
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
	print("=== Tes Trainer NUSAMON ===")
	var db := NusamonData.load_trainers()
	var nusamons := NusamonData.load_nusamons()
	var dunia := NusamonData.load_world()
	cek("trainers.json terbaca", not db.is_empty())
	if db.is_empty() or nusamons.is_empty() or dunia.is_empty():
		quit(1)
		return

	# ---------- lookup trainer
	cek("trainer tak dikenal → {}", TrainerEngine.cari(db, "pak_palapa").is_empty())
	var sari := TrainerEngine.cari(db, "bu_sari")
	cek("Bu Sari ditemukan", not sari.is_empty())
	cek("nama = Bu Sari", String(sari.get("nama", "")) == "Bu Sari")
	cek("profesi = Peternak", String(sari.get("profesi", "")) == "Peternak")
	var gym: Dictionary = sari.get("gym", {})
	cek("gym G1 Normal", int(gym.get("id", 0)) == 1 and String(gym.get("tipe", "")) == "Normal")
	cek("gym di kota_harapan", String(gym.get("kota", "")) == "kota_harapan")

	# ---------- trainer per kota
	cek("trainer_di_kota(kota_harapan) = Bu Sari",
		String(TrainerEngine.trainer_di_kota(db, "kota_harapan").get("id", "")) == "bu_sari")
	cek("rute_1 tanpa trainer", TrainerEngine.trainer_di_kota(db, "rute_1").is_empty())
	cek("kota_arunika punya trainer (Pak Lesto — G2 aktif)",
		String(TrainerEngine.trainer_di_kota(db, "kota_arunika").get("id", "")) == "pak_lesto")

	# ---------- data tim
	var tim: Array = sari.get("tim", [])
	cek("tim = 2 mon", tim.size() == 2)
	cek("Monyet Kecil (23) Lv.8", tim.size() == 2
		and int(tim[0].get("spesies", 0)) == 23 and int(tim[0].get("level", 0)) == 8)
	cek("Ayam Jantan (24) Lv.10", tim.size() == 2
		and int(tim[1].get("spesies", 0)) == 24 and int(tim[1].get("level", 0)) == 10)

	# ---------- buat_tim: instans sesuai urutan data
	var squad := TrainerEngine.buat_tim(db, "bu_sari", nusamons)
	cek("buat_tim = 2 instans", squad.size() == 2, str(squad.size()))
	if squad.size() == 2:
		cek("mon 1 = Monyet Kecil Lv.8",
			String(squad[0].display_name) == "Monyet Kecil" and int(squad[0].level) == 8)
		cek("mon 2 = Ayam Jantan Lv.10",
			String(squad[1].display_name) == "Ayam Jantan" and int(squad[1].level) == 10)
		cek("stat sehat (max_hp > 0, ability terisi)",
			int(squad[0].max_hp) > 0 and int(squad[1].max_hp) > 0
			and String(squad[0].ability) != "" and String(squad[1].ability) != "")
		cek("HP penuh saat dibuat",
			int(squad[0].current_hp) == int(squad[0].max_hp)
			and int(squad[1].current_hp) == int(squad[1].max_hp))
		cek("moveset terisi (>=1 move)", squad[0].move_ids.size() >= 1 and squad[1].move_ids.size() >= 1)
	cek("buat_tim trainer tak dikenal → []", TrainerEngine.buat_tim(db, "tak_ada", nusamons).is_empty())

	# ---------- pratinjau tim & lencana
	var teks := TrainerEngine.tim_teks(db, "bu_sari", nusamons)
	cek("tim_teks memuat nama & level", teks.contains("Monyet Kecil Lv.8")
		and teks.contains("Ayam Jantan Lv.10"), teks)
	cek("tim_teks trainer tak dikenal → ''", TrainerEngine.tim_teks(db, "tak_ada", nusamons) == "")
	var lencana := TrainerEngine.lencana(db, "bu_sari")
	cek("lencana id 1", int(lencana.get("id", 0)) == 1)
	cek("lencana nama = Lencana Harapan", String(lencana.get("nama", "")) == "Lencana Harapan")
	cek("lencana trainer tak dikenal → {}", TrainerEngine.lencana(db, "tak_ada").is_empty())

	# ---------- dialog & hadiah
	var dlg: Dictionary = sari.get("dialog", {})
	cek("dialog intro/menang/kalah terisi",
		String(dlg.get("intro", "")) != "" and String(dlg.get("menang_pemain", "")) != ""
		and String(dlg.get("kalah_pemain", "")) != "")
	cek("hadiah_uang = 1200", int(sari.get("hadiah_uang", 0)) == 1200)

	# ---------- konsistensi lintas-data
	var semua_ok := true
	var badge_seen := {}
	for t in db.get("trainers", []):
		var g: Dictionary = t.get("gym", {})
		var jenis := String(t.get("jenis", "gym"))
		if jenis == "gym":
			var kota_valid := false
			for l in dunia.get("lokasi", []):
				if String(l.get("id", "")) == String(g.get("kota", "")):
					kota_valid = true
			if not kota_valid:
				semua_ok = false
		var n_tim: Array = t.get("tim", [])
		if n_tim.is_empty() or n_tim.size() > 6:
			semua_ok = false
		for e in n_tim:
			if bool(e.get("counter_starter", false)):
				continue   # spesies di-resolve engine dari starter pemain
			if NusamonData.find_species(nusamons, int(e.get("spesies", 0))).is_empty():
				semua_ok = false
		if jenis == "gym":
			if badge_seen.has(int(g.get("id", 0))):
				semua_ok = false
			badge_seen[int(g.get("id", 0))] = true
	cek("semua trainer: gym valid, tim 1..6, spesies valid, lencana unik", semua_ok)

	# gate lencana di world.json merujuk gym yang benar
	var gate_ok := false
	for k in dunia.get("koneksi", []):
		if String(k.get("dari", "")) == "kota_harapan" and String(k.get("ke", "")) == "rute_2":
			var gate: Variant = k.get("gate")
			if gate != null and String(gate.get("jenis", "")) == "lencana" \
					and int(gate.get("id", 0)) == int(gym.get("id", 0)):
				gate_ok = true
	cek("gate Rute 2 di world.json merujuk Lencana gym Bu Sari", gate_ok)

	# ---------- Pak Lesto (G2 Api — Fase 4): tim dengan tahap evolusi
	var lesto := TrainerEngine.cari(db, "pak_lesto")
	cek("Pak Lesto ditemukan", not lesto.is_empty())
	cek("profesi = Penjaga Gunung Kapi", String(lesto.get("profesi", "")) == "Penjaga Gunung Kapi")
	cek("gym G2 Api di kota_arunika",
		int(lesto.get("gym", {}).get("id", 0)) == 2
		and String(lesto.get("gym", {}).get("tipe", "")) == "Api"
		and String(lesto.get("gym", {}).get("kota", "")) == "kota_arunika")
	cek("trainer_di_kota(kota_arunika) = Pak Lesto",
		String(TrainerEngine.trainer_di_kota(db, "kota_arunika").get("id", "")) == "pak_lesto")
	var tim_lesto := TrainerEngine.buat_tim(db, "pak_lesto", nusamons)
	cek("tim Pak Lesto = 2 instans", tim_lesto.size() == 2, str(tim_lesto.size()))
	if tim_lesto.size() == 2:
		cek("mon 1 = Beruang Muda Lv.14 (tahap 0)",
			String(tim_lesto[0].display_name) == "Beruang Muda" and int(tim_lesto[0].level) == 14)
		cek("mon 2 = Ayam Satria Lv.16 (tahap 1)",
			String(tim_lesto[1].display_name) == "Ayam Satria" and int(tim_lesto[1].level) == 16,
			"aktual " + String(tim_lesto[1].display_name))
	var teks_lesto := TrainerEngine.tim_teks(db, "pak_lesto", nusamons)
	cek("tim_teks memakai nama tahap benar",
		teks_lesto.contains("Beruang Muda Lv.14") and teks_lesto.contains("Ayam Satria Lv.16"),
		teks_lesto)
	var lencana_lesto := TrainerEngine.lencana(db, "pak_lesto")
	cek("lencana G2 = Lencana Arunika",
		int(lencana_lesto.get("id", 0)) == 2
		and String(lencana_lesto.get("nama", "")) == "Lencana Arunika")
	cek("hadiah Pak Lesto = Rp 2000", int(lesto.get("hadiah_uang", 0)) == 2000)

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)