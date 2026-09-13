extends SceneTree
## Tes headless Nusadex NUSAMON: lihat/tangkap, idempoten, penjagaan id 1..30.
## Jalankan: godot --headless --script game/tests/test_nusadex.gd
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
	print("=== Tes Nusadex NUSAMON ===")
	Nusadex.reset()
	cek("kosong setelah reset", Nusadex.jumlah_lihat() == 0 and Nusadex.jumlah_tangkap() == 0)

	# ---------- penjagaan id
	cek("lihat id 0 ditolak", not Nusadex.lihat(0))
	cek("lihat id 31 ditolak", not Nusadex.lihat(31))
	cek("tangkap id -1 ditolak", not Nusadex.tangkap(-1))
	cek("tetap kosong", Nusadex.jumlah_lihat() == 0)

	# ---------- lihat
	cek("lihat(1) dicatat", Nusadex.lihat(1) and Nusadex.sudah_lihat(1))
	cek("belum tertangkap", not Nusadex.sudah_tangkap(1))
	cek("lihat(1) ulang idempoten", Nusadex.lihat(1) and Nusadex.jumlah_lihat() == 1)

	# ---------- tangkap
	cek("tangkap(1) dicatat", Nusadex.tangkap(1) and Nusadex.sudah_tangkap(1))
	cek("tangkap implisit lihat", Nusadex.sudah_lihat(1))
	cek("jumlah tangkap = 1", Nusadex.jumlah_tangkap() == 1)
	cek("tangkap(5) → juga terlihat", Nusadex.tangkap(5) and Nusadex.sudah_lihat(5))
	cek("jumlah lihat = 2", Nusadex.jumlah_lihat() == 2)
	cek("sudah_tangkap(2) = false", not Nusadex.sudah_tangkap(2))

	# ---------- penuh 30
	for id in range(1, 31):
		Nusadex.lihat(int(id))
	cek("lihat semua 30", Nusadex.jumlah_lihat() == Nusadex.TOTAL)

	# ---------- reset
	Nusadex.reset()
	cek("reset mengosongkan", Nusadex.jumlah_lihat() == 0 and Nusadex.jumlah_tangkap() == 0)

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)