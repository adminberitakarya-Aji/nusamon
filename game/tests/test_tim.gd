extends SceneTree
## Tes headless Tim/partai NUSAMON: maks 6, anggota aktif, cari spesies,
## pulihkan_semua, dan persistensi via referensi instance.
## Jalankan: godot --headless --script game/tests/test_tim.gd
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
	print("=== Tes Tim NUSAMON ===")
	var data := NusamonData.load_nusamons()
	cek("nusamons.json terbaca", not data.is_empty())
	if data.is_empty():
		quit(1)
		return

	Tim.reset()
	cek("tim kosong setelah reset", Tim.jumlah() == 0)
	cek("aktif() null saat tim kosong", Tim.aktif() == null)

	# ---------- tambah 6 spesies unik (22,23,24,25,26,27) lv10
	for id in [22, 23, 24, 25, 26, 27]:
		var sp := NusamonData.find_species(data, int(id))
		Tim.tambah(NusamonInstance.create(sp, data["detailSpesies"][str(id)], 0, 10))
	cek("tim penuh 6/6", Tim.jumlah() == 6 and Tim.penuh())

	# ---------- penolakan
	var sp7 := NusamonData.find_species(data, 28)
	cek("anggota ke-7 ditolak",
		not Tim.tambah(NusamonInstance.create(sp7, data["detailSpesies"]["28"], 0, 10)))
	cek("tambah null ditolak", not Tim.tambah(null))
	cek("duplikat instance ditolak", not Tim.tambah(Tim.aktif()))
	cek("jumlah tetap 6", Tim.jumlah() == 6)

	# ---------- mon aktif
	cek("aktif default = index 0 (spesies 22)", Tim.aktif().id == 22)
	cek("ubah_aktif(3) valid", Tim.ubah_aktif(3) and Tim.aktif().id == 25)
	cek("ubah_aktif(9) ditolak", not Tim.ubah_aktif(9) and Tim.aktif().id == 25)
	cek("ubah_aktif(-1) ditolak", not Tim.ubah_aktif(-1))

	# ---------- cari spesies
	cek("cari_spesies(23) = 1", Tim.cari_spesies(23) == 1)
	cek("cari_spesies(99) = -1", Tim.cari_spesies(99) == -1)

	# ---------- pulihkan_semua
	var aktif := Tim.aktif()
	aktif.take_damage(aktif.max_hp - 1)
	aktif.status = "racun"
	Tim.anggota[1].take_damage(5)
	cek("pulihkan_semua memulihkan 2", Tim.pulihkan_semua() == 2)
	var semua_bersih := true
	for m in Tim.anggota:
		if m.current_hp != m.max_hp or m.status != "":
			semua_bersih = false
	cek("semua anggota HP penuh & tanpa status", semua_bersih)
	cek("pulihkan ulang = 0 (sudah sehat)", Tim.pulihkan_semua() == 0)

	# ---------- persistensi via referensi
	aktif.level = 9
	cek("referensi tersimpan (level terbaca dari tim)", Tim.aktif().level == 9)

	# ---------- reset
	Tim.reset()
	cek("reset mengosongkan tim", Tim.jumlah() == 0 and Tim.aktif() == null)

	# ---------- ringkasan
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)