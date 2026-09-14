extends SceneTree
## Tes headless battle trainer NUSAMON (Fase 3 langkah 4): antrean → battle vs
## Bu Sari (tim multi-mon), kabur/tangkap diblokir, EXP ×1.5, mon berikutnya
## maju, hadiah + lencana (gate Rute 2 terbuka), dan jalur kalah pemain.
## Jalankan: godot --headless --script game/tests/test_battle_trainer.gd
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
	print("=== Tes Battle Trainer NUSAMON ===")
	Inventori.reset()
	Tim.reset()
	Nusadex.reset()
	Simpanan.hapus()
	Progres.reset()
	var paket: PackedScene = load("res://game/battle/battle_scene.tscn")
	cek("scene battle termuat", paket != null)
	if paket == null:
		quit(1)
		return

	# ---------- 1. antrean → battle trainer aktif otomatis
	TrainerEngine.set_antrean("bu_sari")
	var scene: Control = paket.instantiate()
	root.add_child(scene)
	cek("mode_trainer aktif", scene.mode_trainer)
	cek("trainer_data = Bu Sari",
		String(scene.trainer_data.get("nama", "")) == "Bu Sari")
	cek("tim trainer 2 mon", scene.tim_trainer.size() == 2)
	cek("wild = Monyet Kecil Lv.8 (orde data)",
		String(scene.wild.display_name) == "Monyet Kecil" and int(scene.wild.level) == 8)
	cek("idx_trainer = 0", int(scene.idx_trainer) == 0)
	cek("dialog intro muncul di log",
		scene.log_label.text.contains("Selamat datang di Gym Harapan"))
	cek("log menyebut mengirim Mon", scene.log_label.text.contains("mengirim Monyet Kecil"))
	cek("nusadex: mon trainer terlihat", Nusadex.sudah_lihat(23))
	cek("player = mon aktif tim", scene.player == Tim.aktif() and Tim.jumlah() == 1)

	# ---------- 2. kabur diblokir
	scene._kabur()
	cek("kabur ditolak di battle trainer",
		scene.log_label.text.contains("Tidak bisa kabur dari battle trainer"))

	# ---------- 3. tangkap diblokir (item TIDAK terpakai)
	var stok := Inventori.stok_item("amukan")
	scene._lempar_amukan("amukan")
	cek("tangkap ditolak di battle trainer",
		scene.log_label.text.contains("Tidak bisa menangkap"))
	cek("stok Amukan tidak terpakai", Inventori.stok_item("amukan") == stok,
		"aktual " + str(Inventori.stok_item("amukan")))

	# ---------- 4. mon 1 kalah → mon 2 maju
	var exp_sebelum := int(scene.player.exp_total)
	scene.wild.take_damage(9999)
	scene._akhir_battle(true)
	cek("idx_trainer maju ke 1", int(scene.idx_trainer) == 1)
	cek("wild = Ayam Jantan Lv.10",
		String(scene.wild.display_name) == "Ayam Jantan" and int(scene.wild.level) == 10)
	cek("log: leader kirim mon berikutnya",
		scene.log_label.text.contains("mengirim Ayam Jantan"))
	cek("battle LANJUT (bukan selesai)",
		not scene.log_label.text.contains("Battle selesai") and not scene.turn_aktif)
	cek("nusadex: mon kedua terlihat", Nusadex.sudah_lihat(24))
	cek("EXP pemain bertambah (×1.5 trainer)",
		int(scene.player.exp_total) > exp_sebelum)
	cek("EXP memakai multiplikator trainer",
		int(scene.player.exp_total) - exp_sebelum
		== ExpSystem.exp_gain(int(scene.data["detailSpesies"]["23"].get("baseExpYield", 55)),
			8, true),
		"gain " + str(int(scene.player.exp_total) - exp_sebelum))
	cek("menu aktif kembali setelah ganti mon", not scene.turn_aktif)

	# ---------- 5. mon 2 kalah → menang: hadiah + lencana + gate terbuka
	var uang_sebelum := int(Inventori.uang)
	scene.wild.take_damage(9999)
	scene._akhir_battle(true)
	cek("dialog menang muncul",
		scene.log_label.text.contains("Lencana Harapan"))
	cek("hadiah Rp 1200 masuk", int(Inventori.uang) == uang_sebelum + 1200,
		"aktual " + str(Inventori.uang))
	cek("label uang diperbarui", scene.uang_label.text == "Rp %d" % int(Inventori.uang))
	cek("lencana 1 diperoleh", Progres.punya_lencana(1))
	cek("trainer tercatat kalah", Progres.sudah_kalah_trainer("bu_sari"))
	cek("battle selesai (menang vs trainer)",
		scene.log_label.text.contains("Battle selesai (menang vs trainer)"))
	cek("turn terkunci di akhir battle", scene.turn_aktif)
	var dunia := NusamonData.load_world()
	cek("gate Rute 2 TERBUKA dengan lencana hasil battle",
		bool(WorldEngine.pindah(dunia, "kota_harapan", "rute_2",
			{"lencana": Progres.lencana}).get("ok", false)))

	# ---------- 6. jalur kalah: dialog kalah_pemain
	TrainerEngine.set_antrean("bu_sari")
	var scene2: Control = paket.instantiate()
	root.add_child(scene2)
	cek("scene kedua: mode trainer aktif", scene2.mode_trainer)
	scene2.player.take_damage(9999)
	scene2._akhir_battle(false)
	cek("dialog kalah_pemain muncul",
		scene2.log_label.text.contains("Latih timmu dulu"))
	cek("battle selesai (kalah)", scene2.log_label.text.contains("Battle selesai (kalah)"))

	# ---------- 7. antrean dikonsumsi bersih (scene ketiga = battle liar)
	var scene3: Control = paket.instantiate()
	root.add_child(scene3)
	cek("antrean habis → scene berikut battle liar biasa", not scene3.mode_trainer)

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)