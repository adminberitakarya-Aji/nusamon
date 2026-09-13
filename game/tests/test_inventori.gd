extends SceneTree
## Tes headless inventori NUSAMON: uang, stok, beli/toko, pakai item.
## Jalankan: godot --headless --script game/tests/test_inventori.gd
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
	print("=== Tes Inventori NUSAMON ===")
	var data := NusamonData.load_items()
	cek("items.json terbaca", not data.is_empty())
	if data.is_empty():
		quit(1)
		return

	# ---------- kondisi awal
	Inventori.reset()
	cek("uang awal = 3000", Inventori.uang == 3000, "aktual " + str(Inventori.uang))
	cek("stok awal amukan = 5", Inventori.stok_item("amukan") == 5)
	cek("daftar amukan = 4", Inventori.daftar_amukan().size() == 4)

	# ---------- pakai item
	cek("pakai amukan berhasil", Inventori.pakai_item("amukan"))
	cek("stok amukan turun jadi 4", Inventori.stok_item("amukan") == 4)
	cek("pakai amukan_kuat gagal (stok 0)", not Inventori.pakai_item("amukan_kuat"))
	cek("pakai item tak dikenal gagal", not Inventori.pakai_item("tidak_ada"))

	# ---------- harga
	cek("harga amukan = 200", Inventori.harga("amukan") == 200)
	cek("harga amukan_kuat = 600", Inventori.harga("amukan_kuat") == 600)
	cek("harga amukan_super = 900", Inventori.harga("amukan_super") == 900)
	cek("amukan_nusantara tak dijual (harga -1)", Inventori.harga("amukan_nusantara") == -1)
	cek("harga item tak dikenal = -1", Inventori.harga("tidak_ada") == -1)

	# ---------- beli
	cek("beli amukan berhasil", Inventori.beli("amukan"))
	cek("uang = 2800", Inventori.uang == 2800, "aktual " + str(Inventori.uang))
	cek("stok amukan kembali 5", Inventori.stok_item("amukan") == 5)
	cek("beli amukan_kuat berhasil", Inventori.beli("amukan_kuat"))
	cek("uang = 2200", Inventori.uang == 2200, "aktual " + str(Inventori.uang))
	cek("beli amukan_super berhasil", Inventori.beli("amukan_super"))
	cek("uang = 1300", Inventori.uang == 1300)
	cek("amukan_nusantara tak bisa dibeli", not Inventori.beli("amukan_nusantara"))
	# beli berulang berhenti saat uang tak cukup lagi
	while Inventori.beli("amukan"):
		pass
	cek("beli berulang berhenti saat uang kurang", Inventori.uang < Inventori.harga("amukan"),
		"uang " + str(Inventori.uang))
	cek("beli item tak dikenal gagal", not Inventori.beli("tidak_ada"))

	# ---------- reset
	Inventori.reset()
	cek("reset kembalikan kondisi awal",
		Inventori.uang == 3000 and Inventori.stok_item("amukan") == 5)

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)