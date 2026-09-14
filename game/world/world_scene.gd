extends Control
## World scene prototipe NUSAMON — peta Jawa MVP (GDD §8):
## Desa Sumberrejo → Rute 1 → Kota Harapan → Rute 2 → Kota Arunika.
## UI dibangun programatik (konvensi battle scene). Fase 3 langkah 1:
## traversal + gate lencana; encounter liar & gym = langkah berikutnya.

const SCENE_BATTLE := "res://game/battle/battle_scene.tscn"

var db := {}
var trainers := {}
var nusamons := {}
var rng := RandomNumberGenerator.new()

# --- node UI
var lokasi_nama: Label
var lokasi_jenis: Label
var lokasi_deskripsi: Label
var daftar_tempat: VBoxContainer
var daftar_tujuan: VBoxContainer
var log_label: RichTextLabel
var env_viewport: SubViewport
var env_root: Node3D


func _ready() -> void:
	rng.randomize()
	db = NusamonData.load_world()
	trainers = NusamonData.load_trainers()
	nusamons = NusamonData.load_nusamons()
	if db.is_empty():
		push_error("WorldScene: data dunia gagal dimuat")
		return
	if Progres.lokasi == "":
		Progres.lokasi = String(db.get("lokasi_awal", ""))
	_bangun_ui()
	_catatan("Selamat datang di Pulau Jawa!")
	_catatan("Jelajahi rute (🔍) untuk battle liar; kalahkan Bu Sari untuk membuka Rute 2.")
	_perbarui()


# ------------------------------------------------------------ UI (programatik)

func _label(tek: String, size := 16, warna := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = tek
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", warna)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _panel(pos: Vector2, ukuran: Vector2, warna := Color(0.1, 0.12, 0.16, 0.92)) -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = warna
	st.set_corner_radius_all(8)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", st)
	p.position = pos
	p.custom_minimum_size = ukuran
	add_child(p)
	return p


func _tombol(tek: String, induk: VBoxContainer, callback: Callable) -> Button:
	var b := Button.new()
	b.text = tek
	b.pressed.connect(callback)
	induk.add_child(b)
	return b


func _bangun_ui() -> void:
	# latar sawah
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.34, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# latar 3D environment per lokasi (Fase 3 langkah 6 — CC0/placeholder)
	var env_container := SubViewportContainer.new()
	env_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	env_container.stretch = true
	env_viewport = SubViewport.new()
	env_viewport.transparent_bg = true
	env_container.add_child(env_viewport)
	var kamera := Camera3D.new()
	kamera.position = Vector3(0, 8, 13)
	kamera.rotation_degrees = Vector3(-30, 0, 0)
	env_viewport.add_child(kamera)
	var cahaya := DirectionalLight3D.new()
	cahaya.rotation_degrees = Vector3(-55, 35, 0)
	env_viewport.add_child(cahaya)
	env_root = Node3D.new()
	env_viewport.add_child(env_root)
	add_child(env_container)

	# judul
	var judul := _panel(Vector2(40, 16), Vector2(420, 50), Color(0.08, 0.1, 0.08, 0.92))
	var vj := VBoxContainer.new()
	judul.add_child(vj)
	vj.add_child(_label("🗺 NUSAMON — Pulau Jawa", 20, Color(1.0, 0.92, 0.6)))

	# panel lokasi sekarang (kiri-atas)
	var pl := _panel(Vector2(40, 80), Vector2(420, 170))
	var vl := VBoxContainer.new()
	pl.add_child(vl)
	lokasi_jenis = _label("?", 13, Color(0.6, 0.85, 0.6))
	lokasi_nama = _label("?", 22)
	lokasi_deskripsi = _label("?", 14, Color(0.85, 0.85, 0.8))
	vl.add_child(lokasi_jenis)
	vl.add_child(lokasi_nama)
	vl.add_child(lokasi_deskripsi)

	# panel tempat menarik (kiri-bawah)
	var pt := _panel(Vector2(40, 262), Vector2(420, 190))
	var vt := VBoxContainer.new()
	pt.add_child(vt)
	vt.add_child(_label("📍 Tempat Menarik", 15, Color(0.8, 0.9, 1.0)))
	daftar_tempat = VBoxContainer.new()
	vt.add_child(daftar_tempat)

	# panel tujuan (kanan)
	var pu := _panel(Vector2(480, 80), Vector2(400, 250))
	var vu := VBoxContainer.new()
	pu.add_child(vu)
	vu.add_child(_label("🧭 Pergi ke…", 15, Color(0.8, 0.9, 1.0)))
	daftar_tujuan = VBoxContainer.new()
	vu.add_child(daftar_tujuan)

	# panel log (bawah)
	var plog := _panel(Vector2(480, 342), Vector2(400, 110))
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = false
	log_label.scroll_following = true
	log_label.custom_minimum_size = Vector2(375, 85)
	plog.add_child(log_label)

	# tombol kembali ke battle + save/load (Fase 3 langkah 5)
	var pb := _panel(Vector2(40, 464), Vector2(420, 110))
	var vb := VBoxContainer.new()
	pb.add_child(vb)
	_tombol("⚔ MENU BATTLE", vb, func() -> void:
		get_tree().change_scene_to_file(SCENE_BATTLE))
	_tombol("💾 SIMPAN", vb, func() -> void:
		if Simpanan.simpan():
			_catatan("Progres disimpan (lokasi, lencana, tim, uang).")
		else:
			_catatan("Gagal menyimpan progres."))
	_tombol("📂 MUAT", vb, func() -> void:
		if Simpanan.muat():
			_catatan("Progres dimuat dari simpanan.json.")
			_perbarui()
		else:
			_catatan("Tidak ada berkas simpanan / gagal memuat."))


func _catatan(tek: String) -> void:
	log_label.text += tek + "\n"


# ------------------------------------------------------------ alur dunia

func _progres() -> Dictionary:
	return {"lokasi": Progres.lokasi, "lencana": Progres.lencana}


func _perbarui() -> void:
	var cur := WorldEngine.lokasi(db, Progres.lokasi)
	if cur.is_empty():
		lokasi_nama.text = "?"
		lokasi_deskripsi.text = "Lokasi tidak dikenal: " + Progres.lokasi
		return
	lokasi_jenis.text = "[%s]" % String(cur.get("jenis", "?")).to_upper()
	lokasi_nama.text = String(cur.get("nama", "?"))
	lokasi_deskripsi.text = String(cur.get("deskripsi", "—"))

	# tempat menarik
	for c in daftar_tempat.get_children():
		c.queue_free()
	var tempat: Array = cur.get("tempat", [])
	if tempat.is_empty():
		daftar_tempat.add_child(_label("(tidak ada — area terbuka)", 13, Color(0.65, 0.65, 0.6)))
	# gym yang punya trainer tampil lewat panel khusus di bawah (hindari dobel)
	var trainer_gym := TrainerEngine.trainer_di_kota(trainers, Progres.lokasi)
	for t in tempat:
		if not trainer_gym.is_empty() and String(t.get("id", "")).begins_with("gym_"):
			continue
		daftar_tempat.add_child(_label("• %s" % String(t.get("nama", "?")), 14))
		daftar_tempat.add_child(_label("   %s" % String(t.get("catatan", "")), 12, Color(0.95, 0.75, 0.4)))

	# panel gym (Fase 3 langkah 3): leader, tim, hadiah — battle = langkah 4
	if not trainer_gym.is_empty():
		var gym: Dictionary = trainer_gym.get("gym", {})
		var tid := String(trainer_gym.get("id", ""))
		daftar_tempat.add_child(_label("🏅 GYM %s — %s (%s)" % [
			String(gym.get("tipe", "?")).to_upper(),
			String(trainer_gym.get("nama", "?")),
			String(trainer_gym.get("profesi", "?"))], 14, Color(1.0, 0.85, 0.5)))
		daftar_tempat.add_child(_label("   Tim: %s" % TrainerEngine.tim_teks(
			trainers, tid, nusamons), 12, Color(0.9, 0.9, 0.85)))
		var lencana: Dictionary = trainer_gym.get("lencana", {})
		daftar_tempat.add_child(_label("   Hadiah: %s + Rp %d" % [
			String(lencana.get("nama", "?")), int(trainer_gym.get("hadiah_uang", 0))],
			12, Color(0.95, 0.75, 0.4)))
		var b_tantang := _tombol("⚔ TANTANG %s" % String(trainer_gym.get("nama", "?")).to_upper(),
			daftar_tempat, func() -> void: _tantang_gym(tid))
		if Progres.sudah_kalah_trainer(tid):
			b_tantang.disabled = true
			b_tantang.tooltip_text = "%s sudah dikalahkan (rematch menyusul)" % String(trainer_gym.get("nama", "?"))
			daftar_tempat.add_child(_label("   ✓ Kamu mengalahkan %s" % String(trainer_gym.get("nama", "?")),
				12, Color(0.6, 0.9, 0.6)))
		else:
			b_tantang.disabled = false
			b_tantang.tooltip_text = "Mulai battle trainer!"

	# tujuan
	for c in daftar_tujuan.get_children():
		c.queue_free()
	if String(cur.get("jenis", "")) == "rute":
		_tombol("🔍 JELAJAHI", daftar_tujuan, _cari_encounter)
	for t in WorldEngine.daftar_tujuan(db, Progres.lokasi, _progres()):
		var tujuan_id := String(t.get("id", ""))
		var b := _tombol("→ %s" % String(t.get("nama", "?")), daftar_tujuan,
			func() -> void: _pergi(tujuan_id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if bool(t.get("terkunci", false)):
			b.disabled = true
			b.tooltip_text = String(t.get("alasan", ""))
			daftar_tujuan.add_child(_label("   🔒 %s" % String(t.get("alasan", "")), 12,
				Color(0.95, 0.6, 0.4)))

	# latar 3D per lokasi (Fase 3 langkah 6 — .glb CC0 / placeholder)
	if env_root != null:
		for c in env_root.get_children():
			c.queue_free()
		env_root.add_child(EnvBuilder.pasang(cur))


func _pergi(tujuan_id: String) -> void:
	var hasil := WorldEngine.pindah(db, Progres.lokasi, tujuan_id, _progres())
	if not bool(hasil.get("ok", false)):
		_catatan(String(hasil.get("alasan", "Tidak bisa pindah.")))
		return
	Progres.lokasi = tujuan_id
	_catatan("Sampai di %s." % String(hasil.get("lokasi", {}).get("nama", tujuan_id)))
	Simpanan.simpan()  # progres dunia persisten (v2) — Fase 3 langkah 5
	_perbarui()


## Jelajahi rute → rol peluang encounter → battle liar (Fase 3 langkah 2).
func _cari_encounter() -> void:
	var cur := WorldEngine.lokasi(db, Progres.lokasi)
	if not EncounterSystem.terjadi(cur, rng):
		_catatan("Kamu menyusuri %s... tidak ada apa-apa." % String(cur.get("nama", "?")))
		return
	var hasil := EncounterSystem.encounter_dari_tabel(cur, rng)
	if hasil.is_empty():
		_catatan("Kamu menyusuri %s... tidak ada apa-apa." % String(cur.get("nama", "?")))
		return
	EncounterSystem.set_antrean(int(hasil["spesies"]), int(hasil["level"]))
	_catatan("Sesuatu bergerak di rumput! (masuk battle liar)")
	Simpanan.simpan()  # battle scene auto-load → state sesi tetap segar
	get_tree().change_scene_to_file(SCENE_BATTLE)


## Tantang gym leader → antrean battle → scene battle (Fase 3 langkah 4).
func _tantang_gym(trainer_id: String) -> void:
	if Progres.sudah_kalah_trainer(trainer_id):
		_catatan("%s sudah dikalahkan — rematch menyusul." % trainer_id)
		return
	TrainerEngine.set_antrean(trainer_id)
	_catatan("Kamu melangkah maju menantang gym!")
	Simpanan.simpan()  # battle scene auto-load → state sesi tetap segar
	get_tree().change_scene_to_file(SCENE_BATTLE)