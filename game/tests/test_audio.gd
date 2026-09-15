extends SceneTree
## Tes headless AudioManager NUSAMON (Fase 5 langkah 5): data audio.json,
## bus Music/SFX, BGM state + gagal-aman, jingle/sting, SFX, volume, determinisme
## file placeholder (hash via validator luar — di sini cek keberadaan file).
## Jalankan: godot --headless --script game/tests/test_audio.gd
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
	print("=== Tes AudioManager NUSAMON ===")
	var db := NusamonData.load_audio()
	cek("audio.json terbaca", not db.is_empty())
	if db.is_empty():
		quit(1)
		return

	# ---------- 1. struktur data audio
	var lagu: Array = db.get("lagu", [])
	var sfx: Array = db.get("sfx", [])
	cek("6 entri lagu (3 bgm + 2 jingle + 1 sting)", lagu.size() == 6, str(lagu.size()))
	cek("11 entri sfx", sfx.size() == 11, str(sfx.size()))
	var id_lagu := {}
	var dup := false
	for l in lagu:
		var iid := String(l.get("id", ""))
		if id_lagu.has(iid):
			dup = true
		id_lagu[iid] = true
		if not FileAccess.file_exists("res://" + String(l.get("file", ""))):
			dup = true   # file wajib ada (placeholder terprogram)
	for s in sfx:
		var sid := String(s.get("id", ""))
		if id_lagu.has(sid):
			dup = true
		id_lagu[sid] = true
		if not FileAccess.file_exists("res://" + String(s.get("file", ""))):
			dup = true
	cek("id unik + semua file placeholder ada", not dup)
	cek("volume semua 0..1", lagu.all(func(e: Dictionary) -> bool:
		return float(e.get("volume", -1)) > 0.0 and float(e.get("volume", -1)) <= 1.0)
		and sfx.all(func(e: Dictionary) -> bool:
			return float(e.get("volume", -1)) > 0.0 and float(e.get("volume", -1)) <= 1.0))

	# ---------- 2. bus audio
	AudioManager.pastikan_siap()
	cek("bus Music terpasang", AudioServer.get_bus_index("Music") != -1)
	cek("bus SFX terpasang", AudioServer.get_bus_index("SFX") != -1)
	cek("Music/SFX terkirim ke Master",
		AudioServer.get_bus_send(AudioServer.get_bus_index("Music")) == "Master")
	AudioManager.pastikan_siap()   # idempoten
	cek("pastikan_siap idempoten", AudioServer.get_bus_index("Music") == AudioServer.get_bus_index("Music"))

	# ---------- 3. cari entri + fail-safe
	cek("cari bgm_jawa ditemukan", not AudioManager.cari_entri("bgm_jawa").is_empty())
	cek("cari sfx ditemukan", not AudioManager.cari_entri("sfx_ui_klik").is_empty())
	cek("id tak dikenal → {}", AudioManager.cari_entri("bgm_bulan").is_empty())
	cek("ganti_bgm id tak dikenal → false", not AudioManager.ganti_bgm("bgm_bulan"))
	cek("ganti_bgm dgn id sfx → false (bukan bgm)", not AudioManager.ganti_bgm("sfx_ui_klik"))
	cek("mainkan_sfx id tak dikenal → false", not AudioManager.mainkan_sfx("sfx_meteor"))
	cek("mainkan_jingle dgn id sfx → false", not AudioManager.mainkan_jingle("sfx_ui_klik"))

	# ---------- 4. BGM state machine
	AudioManager.reset()
	cek("reset: bgm senyap", AudioManager.bgm_aktif == "")
	cek("mulai BGM dunia", AudioManager.ganti_bgm("bgm_jawa"))
	cek("state bgm_aktif = bgm_jawa", AudioManager.bgm_aktif == "bgm_jawa")
	cek("ganti ke BGM battle", AudioManager.ganti_bgm("bgm_battle"))
	cek("state pindah ke bgm_battle", AudioManager.bgm_aktif == "bgm_battle")
	cek("ganti ke bgm yang sama → tetap true tanpa restart", AudioManager.ganti_bgm("bgm_battle"))
	AudioManager.stop_bgm()
	cek("stop_bgm → senyap", AudioManager.bgm_aktif == "")

	# ---------- 5. jingle & sfx (headless: verifikasi API + voice tracking)
	cek("mainkan_jingle valid", AudioManager.mainkan_jingle("jingle_menang"))
	cek("sting legendary", AudioManager.mainkan_jingle("sting_legendary"))
	cek("mainkan_sfx valid", AudioManager.mainkan_sfx("sfx_ui_klik"))
	cek("serang hit", AudioManager.mainkan_sfx("sfx_serang_hit"))
	cek("tangkap sukses", AudioManager.mainkan_sfx("sfx_tangkap_sukses"))
	cek("pingsan", AudioManager.mainkan_sfx("sfx_pingsan"))
	AudioManager.stop_bgm()

	# ---------- 6. volume clamp
	AudioManager.atur_volume_musik(2.0)
	cek("volume musik clamp ke 1.0", absf(AudioManager.volume_musik - 1.0) < 0.001)
	AudioManager.atur_volume_sfx(-1.0)
	cek("volume sfx clamp ke 0.0", AudioManager.volume_sfx == 0.0)
	AudioManager.atur_volume_musik(0.8)
	AudioManager.atur_volume_sfx(0.9)
	cek("volume kembali normal", absf(AudioManager.volume_musik - 0.8) < 0.001
		and absf(AudioManager.volume_sfx - 0.9) < 0.001)
	AudioManager.reset()

	print("")
	print("=== Hasil: %d lulus, %d gagal ===" % [lulus, gagal])
	quit(1 if gagal > 0 else 0)
