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
	AudioManager.ganti_bgm("bgm_jawa")   # BGM dunia (Fase 5 langkah 5)
	_bangun_ui()
	_catatan("Selamat datang di Nusantara!")
	_catatan("Jelajahi rute (🔍) untuk battle liar; kumpulkan 8 lencana untuk Liga Nusantara!")
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
	vj.add_child(_label("🗺 NUSAMON — Nusantara", 20, Color(1.0, 0.92, 0.6)))

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
	# item kunci disertakan agar gate dunia jenis "item" bisa dievaluasi (Fase 5)
	return {"lokasi": Progres.lokasi, "lencana": Progres.lencana,
		"item": Inventori.kunci_dimiliki()}


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
		# POI dengan aksi (Fase 4): lab starter — hanya bila belum memilih
		if String(t.get("aksi", "")) == "pilih_starter" and not Progres.sudah_pilih_starter():
			_tombol("🔬 MASUK LABORATORIUM", daftar_tempat, _buka_cutscene_starter)
		elif String(t.get("aksi", "")) == "rival":
			# rival (Fase 4): battle sekali — tim counter-starter, tanpa lencana
			var rid := String(t.get("id", ""))
			if Progres.sudah_kalah_trainer(rid):
				daftar_tempat.add_child(_label("   ✓ Rival sudah dikalahkan", 12,
					Color(0.6, 0.9, 0.6)))
			else:
				_tombol("⚔ LAWAN %s" % String(t.get("nama", "RIVAL")).to_upper(),
					daftar_tempat, func() -> void: _tantang_trainer(rid))
		elif String(t.get("aksi", "")) == "pulihkan":
			_tombol("💤 PULIHKAN TIM", daftar_tempat, _pulihkan_tim)
		elif String(t.get("aksi", "")) == "toko":
			_tombol("🛒 BUKA TOKO", daftar_tempat, _buka_toko_dunia)
		elif String(t.get("aksi", "")) == "tiket":
			_tampilkan_poi_tiket(t)
		elif String(t.get("aksi", "")) == "legendary":
			_tampilkan_poi_legendary(t)
		elif String(t.get("aksi", "")) == "liga":
			_tampilkan_poi_liga(t)
		elif String(t.get("aksi", "")) == "starter_bonus":
			_tampilkan_poi_starter_bonus(t)

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
			daftar_tempat, func() -> void: _tantang_trainer(tid))
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
		AudioManager.mainkan_sfx("sfx_gate_terkunci")
		_catatan(String(hasil.get("alasan", "Tidak bisa pindah.")))
		return
	Progres.lokasi = tujuan_id
	_catatan("Sampai di %s." % String(hasil.get("lokasi", {}).get("nama", tujuan_id)))
	Simpanan.simpan()  # progres dunia persisten (v2) — Fase 3 langkah 5
	_perbarui()


## Jelajahi rute → rol peluang encounter → battle liar (Fase 3 langkah 2).
func _cari_encounter() -> void:
	if Tim.jumlah() == 0:
		_catatan("Pilih Nusamon pertamamu di Laboratorium Prof. Candri dulu!")
		return
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


# ------------------------------------------------------------ POI Fase 5 (tiket / legendary / liga)

const LIGA_URUTAN := ["kak_dinda", "pak_nandra", "bu_waja", "kapten_samudra", "nara"]
const LIGA_NAMA := {"kak_dinda": "Kak Dinda (E1 — Listrik)", "pak_nandra": "Pak Nandra (E2 — Naga)",
	"bu_waja": "Bu Waja (E3 — Baja)", "kapten_samudra": "Kapten Samudra (E4 — Air)",
	"nara": "Juara Nara (Campuran)"}


## POI aksi "tiket": beri item kunci sekali per save bila syarat lencana terpenuhi.
func _tampilkan_poi_tiket(t: Dictionary) -> void:
	var iid := String(t.get("item", ""))
	var syarat := int(t.get("syarat_lencana", 0))
	var nama := Inventori.nama_item(iid)
	if Inventori.stok_item(iid) > 0:
		daftar_tempat.add_child(_label("   ✓ %s sudah di tanganmu" % nama, 12, Color(0.6, 0.9, 0.6)))
		return
	if Progres.jumlah_lencana() < syarat:
		daftar_tempat.add_child(_label("   🔒 Butuh %d lencana (punya %d)" % [
			syarat, Progres.jumlah_lencana()], 12, Color(0.95, 0.6, 0.4)))
		return
	_tombol("🎫 TERIMA %s" % nama.to_upper(), daftar_tempat, func() -> void:
		Inventori.tambah_item(iid, 1)
		_catatan("Kamu menerima %s — jalur laut terbuka!" % nama)
		Simpanan.simpan()
		_perbarui())


## POI aksi "legendary": 1 encounter per save (world-region §5), cek syarat.
func _tampilkan_poi_legendary(t: Dictionary) -> void:
	var sid := int(t.get("spesies", 0))
	if Progres.sudah_jumpai_legendary(sid):
		daftar_tempat.add_child(_label("   ✓ Jejaknya sudah hilang (1× per petualangan)",
			12, Color(0.6, 0.9, 0.6)))
		return
	var syarat_l := int(t.get("syarat_lencana", 0))
	var butuh_item := String(t.get("item", ""))
	if syarat_l > 0 and Progres.jumlah_lencana() < syarat_l:
		daftar_tempat.add_child(_label("   🔒 Butuh %d lencana untuk mendekat" % syarat_l,
			12, Color(0.95, 0.6, 0.4)))
		return
	if butuh_item != "" and Inventori.stok_item(butuh_item) <= 0:
		daftar_tempat.add_child(_label("   🔒 Butuh %s untuk mendekat" % Inventori.nama_item(butuh_item),
			12, Color(0.95, 0.6, 0.4)))
		return
	_tombol("✨ DEKATI", daftar_tempat, func() -> void: _event_legendary(sid, int(t.get("level", 50))))


## Event legendary: tandai sekali-jumpai lalu battle liar (bisa ditangkap).
func _event_legendary(sid: int, level: int) -> void:
	Progres.tandai_legendary(sid)
	EncounterSystem.set_antrean(sid, level)
	var sp := NusamonData.find_species(nusamons, sid)
	_catatan("AURA RAKSASA MUNCUL — %s menjelma di hadapanmu!" % String(sp.get("nama", "?")))
	Simpanan.simpan()  # penanda legendary persisten (1× per save)
	get_tree().change_scene_to_file(SCENE_BATTLE)


## POI aksi "liga": panel Elite Empat + Juara, urutan berantai E1→E4→Juara.
func _tampilkan_poi_liga(t: Dictionary) -> void:
	daftar_tempat.add_child(_label("🏆 LIGA NUSANTARA — syarat 8 lencana", 14, Color(1.0, 0.85, 0.5)))
	if Progres.jumlah_lencana() < 8:
		daftar_tempat.add_child(_label("   🔒 Butuh 8 lencana (punya %d)" % Progres.jumlah_lencana(),
			12, Color(0.95, 0.6, 0.4)))
		return
	for i in LIGA_URUTAN.size():
		var tid: String = LIGA_URUTAN[i]
		if Progres.sudah_kalah_trainer(tid):
			daftar_tempat.add_child(_label("   ✓ %s dikalahkan" % String(LIGA_NAMA[tid]),
				12, Color(0.6, 0.9, 0.6)))
			continue
		# urutan berantai: anggota ke-i terbuka bila i == 0 atau sebelumnya dikalahkan
		if i > 0 and not Progres.sudah_kalah_trainer(LIGA_URUTAN[i - 1]):
			daftar_tempat.add_child(_label("   ⌛ %s — kalahkan penantang sebelumnya dulu" %
				String(LIGA_NAMA[tid]), 12, Color(0.95, 0.6, 0.4)))
			continue
		_tombol("⚔ TANTANG %s" % String(LIGA_NAMA[tid]).to_upper(), daftar_tempat,
			func() -> void: _tantang_trainer(tid))


## POI aksi "starter_bonus": Program Konservasi Prof. Candri (Fase 5 — Nusadex 100%).
## Setelah Juara, pemain menerima line starter yang belum dimiliki (satu per
## interaksi, masuk tim + tercatat Nusadex.lihat/tangkap). Idempoten via Progres.
const BONUS_STARTER_LEVEL := 20

func _tampilkan_poi_starter_bonus(t: Dictionary) -> void:
	if not Progres.sudah_kalah_trainer("nara"):
		daftar_tempat.add_child(_label("   🔒 Terbuka setelah menjadi Juara Nusantara",
			12, Color(0.95, 0.6, 0.4)))
		return
	var kurang: Array = Progres.starter_yang_kurang()
	if kurang.is_empty():
		daftar_tempat.add_child(_label("   ✓ Program selesai — ketiga line starter tercatat",
			12, Color(0.6, 0.9, 0.6)))
		return
	if Tim.jumlah() >= 6:
		daftar_tempat.add_child(_label("   ⚠ Tim penuh (6/6) — lepaskan satu anggota dulu",
			12, Color(0.95, 0.6, 0.4)))
		return
	var sid := int(kurang[0])
	var sp := NusamonData.find_species(nusamons, sid)
	var nama_tahap := "?"
	var tahapan: Array = sp.get("tahapan", [])
	if not tahapan.is_empty():
		nama_tahap = String(tahapan[0].get("nama", "?"))
	_tombol("🎁 TERIMA %s" % String(nama_tahap).to_upper(), daftar_tempat,
		func() -> void: _terima_starter_bonus(sid))


## Beri satu starter bonus (dipanggil tombol POI; satu per interaksi).
func _terima_starter_bonus(sid: int) -> void:
	if Progres.sudah_terima_starter_bonus(sid) or Tim.penuh():
		return
	var sp := NusamonData.find_species(nusamons, sid)
	var mon := NusamonInstance.create(
		sp, nusamons["detailSpesies"][str(sid)], 0, BONUS_STARTER_LEVEL)
	if not Tim.tambah(mon):
		return
	Progres.tandai_starter_bonus(sid)
	Nusadex.lihat(sid)
	Nusadex.tangkap(sid)
	AudioManager.mainkan_sfx("sfx_tangkap_sukses")
	_catatan("Prof. Candri: Hasil program konservasi kami — %s! Rawat dia baik-baik." %
		mon.display_name)
	_catatan("Tercatat di Nusadex: #%02d %s (Lv.%d)" % [sid, mon.display_name, mon.level])
	Simpanan.simpan()
	_perbarui()


# ------------------------------------------------------------ cutscene starter (Fase 4)

const STARTER_LEVEL := 5
const STARTER_IDS := [1, 2, 3]           # Rimau (Api) / Orangutan (Daun) / Penyu (Air)

var cutscene_baris: Array = []
var cutscene_idx := 0
var cutscene_overlay: Control = null


## Masuk laboratorium → cutscene Prof. Candri → pilih starter.
func _buka_cutscene_starter() -> void:
	var lab := WorldEngine.lokasi(db, Progres.lokasi)
	var dialog: Array = []
	for t in lab.get("tempat", []):
		if String(t.get("id", "")) == "lab_candri":
			dialog = t.get("dialog", [])
	cutscene_baris = dialog
	cutscene_idx = 0
	_tampilkan_langkah_cutscene()


func _tampilkan_langkah_cutscene() -> void:
	if cutscene_overlay != null:
		cutscene_overlay.queue_free()
		cutscene_overlay = null
	# overlay layar penuh — memblok interaksi panel di belakangnya
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	cutscene_overlay = overlay
	var panel := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.1, 0.08, 0.97)
	st.set_corner_radius_all(10)
	st.content_margin_left = 20
	st.content_margin_right = 20
	st.content_margin_top = 16
	st.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", st)
	panel.position = Vector2(170, 160)
	panel.custom_minimum_size = Vector2(810, 330)
	overlay.add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	if cutscene_idx < cutscene_baris.size():
		# langkah dialog: teks + tombol lanjut
		v.add_child(_label("Prof. Candri:", 14, Color(0.6, 0.9, 0.6)))
		v.add_child(_label(String(cutscene_baris[cutscene_idx]), 18))
		var spasi := Control.new()
		spasi.custom_minimum_size = Vector2(0, 14)
		v.add_child(spasi)
		_tombol_layar(v, "LANJUT ▶", func() -> void:
			cutscene_idx += 1
			_tampilkan_langkah_cutscene())
	else:
		# langkah akhir: pilihan starter (data nusamons.json: nama & tipe tahap 0)
		v.add_child(_label("Pilih Nusamon pertamamu — sahabat petualanganmu!",
			18, Color(1.0, 0.92, 0.6)))
		var spasi := Control.new()
		spasi.custom_minimum_size = Vector2(0, 10)
		v.add_child(spasi)
		for sid in STARTER_IDS:
			var sp := NusamonData.find_species(nusamons, sid)
			var tahap0: Dictionary = sp.get("tahapan", [{}])[0]
			var tipe := " / ".join(tahap0.get("tipe", []))
			var b := _tombol_layar(v, "%s — tipe %s" % [String(tahap0.get("nama", "?")), tipe],
				func() -> void: _pilih_starter(sid))
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT


func _tombol_layar(induk: Container, tek: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = tek
	b.pressed.connect(cb)
	induk.add_child(b)
	return b


## Terima starter: masuk tim Lv.%d, Nusadex terisi, progres terkunci & tersimpan.
func _pilih_starter(sid: int) -> void:
	if Progres.sudah_pilih_starter():
		return
	Progres.pilih_starter(sid)
	var sp := NusamonData.find_species(nusamons, sid)
	var mon := NusamonInstance.create(sp, nusamons["detailSpesies"][str(sid)], 0, STARTER_LEVEL)
	Tim.tambah(mon)
	Nusadex.lihat(sid)
	Nusadex.tangkap(sid)
	Simpanan.simpan()  # starter persisten (Simpanan v2)
	_tutup_cutscene()
	_catatan("Prof. Candri: Pilihan bagus! Jaga %s dengan baik, ya." % mon.display_name)
	_catatan("Petualangan dari Desa Sumberrejo dimulai — %s menyertainya! (Lv.%d)" % [
		mon.display_name, STARTER_LEVEL])
	_perbarui()


func _tutup_cutscene() -> void:
	if cutscene_overlay != null:
		cutscene_overlay.queue_free()
		cutscene_overlay = null


# ------------------------------------------------------------ pusat pemulihan & toko (Fase 4)

## Pusat pemulihan: pulihkan seluruh tim (HP penuh + bersihkan status), gratis.
func _pulihkan_tim() -> void:
	if Tim.jumlah() == 0:
		_catatan("Belum punya Nusamon — pilih starter di Laboratorium dulu!")
		return
	var n := Tim.pulihkan_semua()
	Simpanan.simpan()
	AudioManager.mainkan_sfx("sfx_pulihkan")
	if n > 0:
		_catatan("Tim dipulihkan sepenuhnya! (%d Nusamon kembali bugar)" % Tim.jumlah())
	else:
		_catatan("Timmu sudah dalam kondisi prima.")
	_perbarui()


# --- overlay toko (semua tier Amukan; Nusantara = hadiah event, tidak dijual)
var toko_overlay: Control = null


func _buka_toko_dunia() -> void:
	_tampilkan_toko()


func _tampilkan_toko() -> void:
	if toko_overlay != null:
		toko_overlay.queue_free()
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	toko_overlay = overlay
	var panel := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.1, 0.08, 0.97)
	st.set_corner_radius_all(10)
	st.content_margin_left = 20
	st.content_margin_right = 20
	st.content_margin_top = 16
	st.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", st)
	panel.position = Vector2(230, 90)
	panel.custom_minimum_size = Vector2(690, 470)
	overlay.add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	v.add_child(_label("🛒 TOKO — Amukan semua tier", 20, Color(1.0, 0.92, 0.6)))
	v.add_child(_label("Uang: Rp %d" % Inventori.uang, 15, Color(1.0, 0.9, 0.5)))
	var spasi := Control.new()
	spasi.custom_minimum_size = Vector2(0, 8)
	v.add_child(spasi)
	for it in Inventori.daftar_amukan():
		var iid := String(it.get("id", ""))
		var nama := String(it.get("nama", iid))
		var harga := Inventori.harga(iid)
		if harga < 0:
			# hadiah event (mis. Amukan Nusantara) — tidak dijual
			v.add_child(_label("%s — hadiah event (tidak dijual) [stok %d]" % [
				nama, Inventori.stok_item(iid)], 14, Color(0.7, 0.7, 0.65)))
			continue
		var baris := HBoxContainer.new()
		v.add_child(baris)
		var teks := _label("%s — Rp %d [stok %d]" % [
			nama, harga, Inventori.stok_item(iid)], 14)
		teks.custom_minimum_size = Vector2(380, 0)
		baris.add_child(teks)
		var b := _tombol_layar(baris, "BELI", func() -> void: _beli_toko(iid))
		b.disabled = Inventori.uang < harga
	var spasi2 := Control.new()
	spasi2.custom_minimum_size = Vector2(0, 10)
	v.add_child(spasi2)
	_tombol_layar(v, "TUTUP", _tutup_toko)


func _beli_toko(iid: String) -> void:
	if Inventori.beli(iid):
		AudioManager.mainkan_sfx("sfx_ui_klik")
		_catatan("Membeli %s. (stok %d, uang Rp %d)" % [
			iid, Inventori.stok_item(iid), Inventori.uang])
		Simpanan.simpan()
	_tampilkan_toko()   # segarkan harga/stok/keadaan tombol


func _tutup_toko() -> void:
	if toko_overlay != null:
		toko_overlay.queue_free()
		toko_overlay = null
	_perbarui()


## Tantang trainer (gym/rival) → antrean battle → scene battle.
func _tantang_trainer(trainer_id: String) -> void:
	if Tim.jumlah() == 0:
		_catatan("Pilih Nusamon pertamamu di Laboratorium Prof. Candri dulu!")
		return
	if Progres.sudah_kalah_trainer(trainer_id):
		_catatan("%s sudah dikalahkan — rematch menyusul." % trainer_id)
		return
	TrainerEngine.set_antrean(trainer_id)
	_catatan("Kamu maju menerima tantangan!")
	Simpanan.simpan()  # battle scene auto-load → state sesi tetap segar
	get_tree().change_scene_to_file(SCENE_BATTLE)