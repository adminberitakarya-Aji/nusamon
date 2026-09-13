extends SceneTree
## Tes headless Latihan (EV-lite) + Simpanan (save/load) + helper model.
## Jalankan: godot --headless --script game/tests/test_latihan_simpan.gd
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


func _buat(data: Dictionary, id: int, level := 5) -> NusamonInstance:
	return NusamonInstance.create(
		NusamonData.find_species(data, id), data["detailSpesies"][str(id)], 0, level)


func _init() -> void:
	print("=== Tes Latihan & Simpanan NUSAMON ===")
	var data := NusamonData.load_nusamons()
	cek("data terbaca", not data.is_empty())
	if data.is_empty():
		quit(1)
		return
	Inventori.reset()
	Tim.reset()
	Nusadex.reset()
	Simpanan.hapus()

	# ---------- 1. Latihan: konversi 4:1
	var rimau := _buat(data, 1)  # atk runtime lv5 = 12
	cek("atk dasar 12", int(rimau.stats["atk"]) == 12)
	var d := rimau.tambah_latihan("atk", 12)
	cek("12 poin diterima", d == 12 and rimau.latihan_total == 12)
	cek("stats dasar tidak berubah", int(rimau.stats["atk"]) == 12)
	cek("bonus 4:1 = +3 (12→15)", int(rimau.stats_efektif["atk"]) == 15,
		"aktual " + str(rimau.stats_efektif["atk"]))

	# ---------- 2. cap stat 25
	rimau.tambah_latihan("atk", 100)
	cek("cap per-stat 25", int(rimau.latihan["atk"]) == 25 and rimau.latihan_total == 25)
	cek("cap stat → poin tambahan ditolak", rimau.tambah_latihan("atk", 5) == 0)
	cek("bonus max per-stat = +6 (25/4)", int(rimau.stats_efektif["atk"]) == 18)

	# ---------- 3. cap total 50
	rimau.tambah_latihan("spe", 50)
	cek("cap total 50 (spe dapat 25)", rimau.latihan_total == 50 and int(rimau.latihan["spe"]) == 25)
	cek("cap total → stat lain ditolak", rimau.tambah_latihan("def", 3) == 0)
	cek("kunci invalid ditolak", rimau.tambah_latihan("hp", 3) == 0)

	# ---------- 4. Teh Herba (reset latihan)
	cek("harga teh_herba = 500", Inventori.harga("teh_herba") == 500)
	cek("beli teh_herba", Inventori.beli("teh_herba"))
	cek("pakai teh_herba dari inventori", Inventori.pakai_item("teh_herba"))
	rimau.reset_latihan()
	cek("reset latihan → bersih",
		rimau.latihan_total == 0 and int(rimau.stats_efektif["atk"]) == 12)

	# ---------- 5. save: snapshot state
	Tim.reset()
	Tim.tambah(rimau)
	rimau.tambah_latihan("atk", 25)
	rimau.take_damage(5)
	Nusadex.lihat(3)
	Nusadex.tangkap(7)
	var state := Simpanan.ambil_state()
	cek("state memuat 1 anggota tim", (state["tim"] as Array).size() == 1)
	# rusak state sesi, lalu restore
	Inventori.uang = 123
	Tim.reset()
	Nusadex.reset()
	Simpanan.terapkan(state)
	cek("uang direstore", Inventori.uang == 2500, "aktual " + str(Inventori.uang))
	cek("tim direstore 1 anggota", Tim.jumlah() == 1)
	var m := Tim.aktif()
	cek("level direstore (5)", m.level == 5)
	cek("hp direstore", m.current_hp == m.max_hp - 5)
	cek("latihan direstore (atk 25)",
		int(m.latihan.get("atk", 0)) == 25 and m.latihan_total == 25)
	cek("stats_efektif direstore (+6)", int(m.stats_efektif["atk"]) == 18)
	cek("nusadex direstore",
		Nusadex.sudah_lihat(3) and Nusadex.sudah_tangkap(7) and Nusadex.jumlah_tangkap() == 1)

	# ---------- 6. save/load via file user://
	Inventori.reset()
	Nusadex.reset()
	var uang_ekspektasi := Inventori.uang
	var level_ekspektasi := 0
	if Tim.jumlah() > 0:
		level_ekspektasi = Tim.aktif().level
	cek("simpan() berhasil", Simpanan.simpan())
	cek("save file ada", FileAccess.file_exists(Simpanan.PATH))
	Inventori.uang = 77
	Tim.reset()
	Nusadex.reset()
	cek("muat() berhasil", Simpanan.muat())
	cek("state file direstore (uang & tim)",
		Inventori.uang == uang_ekspektasi and Tim.jumlah() == 1
		and Tim.aktif().level == level_ekspektasi)

	# ---------- 7. hapus & muat tanpa file
	cek("hapus save", Simpanan.hapus())
	cek("file hilang", not FileAccess.file_exists(Simpanan.PATH))
	cek("muat tanpa file → false", not Simpanan.muat())

	# ---------- 8. helper model (tahap 2/3 → tampil bila .glb ada)
	cek("id_model 'Anak Rimau'", NusamonData.id_model("Anak Rimau") == "anak_rimau")
	cek("id_model 'Kantong Semar Kecil'",
		NusamonData.id_model("Kantong Semar Kecil") == "kantong_semar_kecil")
	cek("path_model", NusamonData.path_model("Rimau Muda")
		== "res://assets/models/rimau_muda.glb")
	cek("model tahap 2/3 belum digenerate (Blender) → pratinjau diam",
		not ResourceLoader.exists(NusamonData.path_model("Rimau Muda")))

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)