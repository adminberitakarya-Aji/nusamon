extends SceneTree
## Tes headless scene battle NUSAMON: UI terbangun + battle penuh disimulasikan
## (lempar Amukan + serang sampai salah satu pingsan/tertangkap).
## Jalankan: godot --headless --script game/tests/test_scene.gd
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
	# SceneTree belum aktif saat _init — tunda sampai iterasi pertama,
	# sehingga add_child memicu _ready() scene dengan benar.
	_mulai.call_deferred()


func _mulai() -> void:
	print("=== Tes Scene Battle NUSAMON ===")
	# inventori, tim, nusadex sesi: kondisi awal deterministik untuk tes
	Inventori.reset()
	Inventori.tambah_item("amukan_super", 3)
	Tim.reset()
	Nusadex.reset()
	var paket: PackedScene = load("res://game/battle/battle_scene.tscn")
	cek("scene battle termuat", paket != null)
	if paket == null:
		quit(1)
		return
	var scene: Control = paket.instantiate()
	root.add_child(scene)

	# ---------- 1. UI terbangun & battle siap
	cek("panel musuh terisi nama", scene.wild_nama.text != "")
	cek("panel pemain terisi nama", scene.p_nama.text != "")
	cek("HP bar musuh tersetel", scene.wild_hp.max_value > 0)
	cek("player dibuat", scene.player != null)
	cek("wild dibuat", scene.wild != null)
	cek("tahap stat awal 0", int(scene.player.stat_stages.get("atk", 99)) == 0)
	cek("PP move terisi", int(scene.player.move_pp.get("cakaran", 0)) > 0)
	cek("stok awal amukan = 5", Inventori.stok_item("amukan") == 5)
	cek("label uang = Rp 3000", scene.uang_label.text == "Rp 3000",
		"aktual " + scene.uang_label.text)
	cek("tim default dibuat (1/6)", Tim.jumlah() == 1, "tim " + str(Tim.jumlah()))
	cek("player = mon aktif tim", scene.player == Tim.aktif())
	cek("label tim terisi", scene.tim_label.text.contains("Tim 1/6"),
		"aktual " + scene.tim_label.text)
	cek("nusadex: wild terlihat", Nusadex.sudah_lihat(scene.wild.id) and Nusadex.jumlah_lihat() == 1)

	# ---------- 2. menu move menampilkan PP & men-disable yang habis
	scene._buka_menu_move()
	cek("menu move punya tombol", scene.menu_move.get_child_count() > 1)
	scene._tutup_sub_menu()

	# ---------- 2b. toko: beli Amukan memakai uang
	scene._buka_menu_toko()
	cek("menu toko terbuka", scene.menu_toko.visible)
	scene._beli_item("amukan")
	cek("uang setelah beli = 2800", Inventori.uang == 2800, "aktual " + str(Inventori.uang))
	cek("stok amukan setelah beli = 6", Inventori.stok_item("amukan") == 6)
	cek("beli item event ditolak", not Inventori.beli("amukan_nusantara"))
	scene._tutup_sub_menu()

	# ---------- 3. lempar Amukan (boleh gagal/berhasil — hasil tercatat di log)
	for i in 3:
		if scene.log_label.text.contains("Battle selesai"):
			break
		scene._lempar_amukan("amukan_super")
	cek("percobaan tangkap tercatat di log",
		scene.log_label.text.contains("Amukan") or scene.log_label.text.contains("tertangkap"))
	cek("stok amukan_super berkurang saat lempar",
		Inventori.stok_item("amukan_super") <= 2,
		"aktual " + str(Inventori.stok_item("amukan_super")))

	# ---------- 4. simulasi battle penuh sampai selesai
	var iterasi := 0
	while not scene.log_label.text.contains("Battle selesai") and iterasi < 300:
		scene._giliran(true, scene._move_pemain_acak())
		iterasi += 1
	cek("battle selesai dalam simulasi",
		scene.log_label.text.contains("Battle selesai"), "iterasi=" + str(iterasi))
	cek("turn terkunci di akhir battle", scene.turn_aktif)
	cek("moveset pemain tersedia", scene.player.move_ids.size() > 0)

	# ---------- 5. tangkap pasti (Amukan Nusantara) → masuk tim
	# bangun battle liar "baru" secara terkontrol (log & giliran direset)
	var tim_sebelum := Tim.jumlah()
	var tangkap_sebelum := Nusadex.jumlah_tangkap()
	scene.log_label.text = ""
	scene.turn_aktif = false
	var id_baru := 28  # Ikan Badut (Common, single-stage)
	var sp_baru := NusamonData.find_species(scene.data, id_baru)
	scene.wild_detail = scene.data["detailSpesies"][str(id_baru)]
	scene.wild = NusamonInstance.create(sp_baru, scene.wild_detail, 0, 10)
	# lemahkan dulu: a = rate*bonus*(3m-2c)/3m — butuh HP < ~83% agar a >= 255
	scene.wild.take_damage(int(ceil(float(scene.wild.max_hp) * 0.8)))
	Inventori.tambah_item("amukan_nusantara", 1)
	scene._lempar_amukan("amukan_nusantara")  # a >= 255 → tangkap pasti
	cek("tangkap pasti → log tertangkap", scene.log_label.text.contains("tertangkap"))
	cek("hasil tangkap masuk tim", Tim.jumlah() == tim_sebelum + 1,
		"tim " + str(Tim.jumlah()))
	cek("anggota baru = wild yang ditangkap",
		Tim.anggota[Tim.jumlah() - 1] == scene.wild)
	cek("battle berakhir setelah tangkap", scene.log_label.text.contains("Battle selesai"))
	cek("tambah ulang wild yang sama ditolak", not Tim.tambah(scene.wild))
	cek("nusadex: tangkap tercatat",
		Nusadex.sudah_tangkap(28) and Nusadex.jumlah_tangkap() == tangkap_sebelum + 1)

	# ---------- 6. switch/tukar mon saat battle (GDD §4.1)
	scene.log_label.text = ""
	scene.turn_aktif = false
	var id_lain := 22  # Rusa
	var sp_rusa := NusamonData.find_species(scene.data, id_lain)
	scene.wild_detail = scene.data["detailSpesies"][str(id_lain)]
	scene.wild = NusamonInstance.create(sp_rusa, scene.wild_detail, 0, 5)
	var aktif_lama: NusamonInstance = Tim.aktif()
	var target_idx := -1
	for i in Tim.jumlah():
		if Tim.anggota[i] != aktif_lama and not Tim.anggota[i].is_fainted():
			target_idx = i
			break
	cek("ada anggota non-aktif sehat untuk ganti", target_idx >= 0)
	scene._buka_menu_ganti()
	cek("menu ganti terbuka", scene.menu_ganti.visible)
	scene._ganti_mon(target_idx)
	cek("mon aktif berganti", Tim.aktif() != aktif_lama)
	cek("player mengikuti mon aktif", scene.player == Tim.aktif())
	cek("log mencatat tukar", scene.log_label.text.contains("maju"))

	# ---------- 7. Nusadex UI: layar daftar + detail
	scene._buka_nusadex()
	cek("panel nusadex terbuka", scene.dex_panel.visible)
	cek("daftar 30 entri", scene.dex_daftar.get_child_count() == Nusadex.TOTAL)
	scene._pilih_dex(27)  # Ikan Badut — tertangkap di bagian 5
	cek("detail tertangkap lengkap",
		scene.dex_detail.text.contains("Ikan Badut") and scene.dex_detail.text.contains("Deskripsi:"),
		"isi: " + scene.dex_detail.text.left(80))
	cek("header progres", scene.dex_header.text.contains("terlihat"))
	scene._tutup_nusadex()
	cek("panel nusadex tertutup", not scene.dex_panel.visible)

	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)

