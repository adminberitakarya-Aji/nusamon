extends Control
## Battle scene prototipe NUSAMON — UI dibangun programatik.
## Pemakaian: jalankan proyek (scene utama) → battle vs Nusamon liar.
## Sistem aktif: serang (4 move, PP), tahap stat (buff/debuff/heal), status,
## ability (12), Amukan (4 jenis + stok), tim (maks. 6), toko, kabur, EXP, evolusi.

const WILD_IDS := [22, 23, 24]          # rusa, monyet, ayam (Common — Jawa)
const WILD_LEVEL_RANGE := [2, 6]
const PLAYER_ID := 1                    # placeholder bila starter belum dipilih (Fase 4)
const PLAYER_LEVEL := 5

var data := {}
var chart := {}
var moves_db := {}
var rng := RandomNumberGenerator.new()

var player: NusamonInstance
var wild: NusamonInstance
var wild_detail := {}
var turn_aktif := false                 # kunci input selama animasi/log

# --- node UI
var wild_nama: Label
var wild_lv: Label
var wild_hp: ProgressBar
var wild_status: Label
var p_nama: Label
var p_lv: Label
var p_hp: ProgressBar
var p_hp_text: Label
var p_status: Label
var p_exp: ProgressBar
var log_label: RichTextLabel
var menu_utama: VBoxContainer
var menu_move: VBoxContainer
var menu_ball: VBoxContainer
var menu_toko: VBoxContainer
var uang_label: Label
var tim_label: Label
var menu_ganti: VBoxContainer
var dex_panel: PanelContainer
var dex_header: Label
var dex_daftar: VBoxContainer
var dex_detail: RichTextLabel
var p_latihan: Label
var pratinjau_wild: Node = null
var pratinjau_player: Node = null
var percobaan_kabur := 0                 # kabur: +30 tiap percobaan (C-3)
var mode_trainer := false                # battle trainer: tanpa kabur/tangkap, tim multi-mon
var trainers_db := {}
var trainer_data := {}
var tim_trainer: Array = []              # tim gym leader (orde data = orde dikirim)
var idx_trainer := 0


func _ready() -> void:
	rng.randomize()
	data = NusamonData.load_nusamons()
	chart = NusamonData.load_type_chart()
	moves_db = NusamonData.load_moves()
	trainers_db = NusamonData.load_trainers()
	if data.is_empty() or chart.is_empty() or moves_db.is_empty():
		push_error("BattleScene: data game gagal dimuat")
		return
	_bangun_ui()
	_auto_muat()
	_mulai_battle()


## Dispatch: battle trainer (antrean dari world scene) atau battle liar prototipe.
func _mulai_battle() -> void:
	var tid := TrainerEngine.ambil_antrean()
	if tid != "":
		_mulai_battle_trainer(tid)
	else:
		_mulai_battle_liar()


## Siapkan tim pemain: buat mon default bila kosong, pulihkan yang pingsan
## (placeholder pusat pemulihan — Fase 2/3), lalu mon aktif jadi player.
func _siapkan_pemain() -> void:
	if Tim.jumlah() == 0:
		# starter hasil pemilihan di Lab (Fase 4) — placeholder anak rimau bila belum
		var id_p := Progres.starter_id if Progres.sudah_pilih_starter() else PLAYER_ID
		var spesies_p := NusamonData.find_species(data, id_p)
		Tim.tambah(NusamonInstance.create(
			spesies_p, data["detailSpesies"][str(id_p)], 0, PLAYER_LEVEL))
	if Tim.pulihkan_semua() > 0:
		_log("Tim dipulihkan di pusat pemulihan.")
	player = Tim.aktif()  # EXP/level/evolusi tersimpan di anggota tim


## Battle vs gym leader (Fase 3 langkah 4): tim multi-mon, tanpa kabur/tangkap,
## EXP ×1.5 (multiplikator trainer di ExpSystem), hadiah uang + lencana.
func _mulai_battle_trainer(tid: String) -> void:
	trainer_data = TrainerEngine.cari(trainers_db, tid)
	if trainer_data.is_empty():
		push_error("BattleScene: trainer tidak dikenal: " + tid)
		_mulai_battle_liar()
		return
	mode_trainer = true
	tim_trainer = TrainerEngine.buat_tim(trainers_db, tid, data)
	idx_trainer = 0
	percobaan_kabur = 0
	_siapkan_pemain()
	wild = tim_trainer[0]
	wild_detail = data["detailSpesies"][str(wild.id)]
	Nusadex.lihat(wild.id)
	_log("⚔ Battle Trainer — %s (%s)!" % [
		String(trainer_data.get("nama", "?")), String(trainer_data.get("profesi", "?"))])
	_log(String(trainer_data.get("dialog", {}).get("intro", "")))
	_mon_masuk(player, wild)
	_mon_masuk(wild, player)
	_log("%s mengirim %s! (Lv.%d)" % [
		String(trainer_data.get("nama", "?")), wild.display_name, wild.level])
	_update_bars()
	_perbarui_model()


# ------------------------------------------------------------ UI (programatik)

func _label(tek: String, size := 16, warna := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = tek
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", warna)
	return l


func _hp_bar(warna := Color(0.3, 0.85, 0.3)) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(240, 18)
	var fill := StyleBoxFlat.new()
	fill.bg_color = warna
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


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


func _tombol_menu(tek: String, induk: VBoxContainer, callback: Callable) -> Button:
	var b := Button.new()
	b.text = tek
	b.pressed.connect(callback)
	induk.add_child(b)
	return b


func _bangun_ui() -> void:
	# latar
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.3, 0.25)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# panel musuh (kiri-atas)
	var musuh := _panel(Vector2(40, 30), Vector2(320, 110))
	var vm := VBoxContainer.new()
	musuh.add_child(vm)
	wild_nama = _label("?", 18)
	wild_lv = _label("Lv.?", 14, Color(0.9, 0.85, 0.5))
	wild_hp = _hp_bar(Color(0.9, 0.4, 0.3))
	wild_status = _label("", 13, Color(0.8, 0.5, 0.9))
	vm.add_child(wild_nama)
	vm.add_child(wild_lv)
	vm.add_child(wild_hp)
	vm.add_child(wild_status)

	# panel pemain (kanan-bawah)
	var pemain := _panel(Vector2(560, 300), Vector2(360, 140))
	var vp := VBoxContainer.new()
	pemain.add_child(vp)
	p_nama = _label("?", 18)
	p_lv = _label("Lv.?", 14, Color(0.9, 0.85, 0.5))
	p_hp = _hp_bar()
	p_hp_text = _label("HP ?/?", 13)
	p_status = _label("", 13, Color(0.8, 0.5, 0.9))
	p_latihan = _label("", 12, Color(0.6, 0.8, 0.6))
	p_exp = _hp_bar(Color(0.35, 0.55, 0.95))
	p_exp.custom_minimum_size = Vector2(240, 8)
	p_exp.max_value = 1
	vp.add_child(p_nama)
	vp.add_child(p_lv)
	vp.add_child(p_hp)
	vp.add_child(p_hp_text)
	vp.add_child(p_status)
	vp.add_child(p_latihan)
	vp.add_child(p_exp)

	# log battle (bawah)
	var panel_log := _panel(Vector2(40, 300), Vector2(500, 140))
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = false
	log_label.scroll_following = true
	log_label.custom_minimum_size = Vector2(470, 115)
	panel_log.add_child(log_label)

	# menu utama (kanan)
	menu_utama = VBoxContainer.new()
	menu_utama.position = Vector2(930, 300)
	menu_utama.custom_minimum_size = Vector2(150, 140)
	add_child(menu_utama)
	_tombol_menu("⚔ SERANG", menu_utama, _buka_menu_move)
	_tombol_menu("🎒 AMUKAN", menu_utama, _buka_menu_ball)
	_tombol_menu("🔄 GANTI", menu_utama, _buka_menu_ganti)
	_tombol_menu("🏃 KABUR", menu_utama, _kabur)
	_tombol_menu("📖 NU SADEX", menu_utama, _buka_nusadex)
	_tombol_menu("🛒 TOKO", menu_utama, _buka_menu_toko)
	_tombol_menu("🌍 DUNIA", menu_utama, _ke_dunia)
	_tombol_menu("💾 SIMPAN", menu_utama, _tombol_simpan)
	_tombol_menu("📂 MUAT", menu_utama, _tombol_muat)

	# menu move (muncul saat serang)
	menu_move = VBoxContainer.new()
	menu_move.position = Vector2(930, 300)
	menu_move.custom_minimum_size = Vector2(150, 160)
	menu_move.visible = false
	add_child(menu_move)

	# menu Amukan
	menu_ball = VBoxContainer.new()
	menu_ball.position = Vector2(930, 300)
	menu_ball.custom_minimum_size = Vector2(150, 160)
	menu_ball.visible = false
	add_child(menu_ball)

	# menu Toko
	menu_toko = VBoxContainer.new()
	menu_toko.position = Vector2(900, 300)
	menu_toko.custom_minimum_size = Vector2(210, 170)
	menu_toko.visible = false
	add_child(menu_toko)

	# menu Ganti (daftar anggota tim)
	menu_ganti = VBoxContainer.new()
	menu_ganti.position = Vector2(850, 300)
	menu_ganti.custom_minimum_size = Vector2(260, 200)
	menu_ganti.visible = false
	add_child(menu_ganti)

	# panel uang (kanan-atas)
	var panel_uang := _panel(Vector2(930, 30), Vector2(150, 50))
	uang_label = _label("Rp ?", 15, Color(1.0, 0.9, 0.5))
	panel_uang.add_child(uang_label)
	_update_uang()

	# panel tim (di bawah panel uang)
	var panel_tim := _panel(Vector2(930, 92), Vector2(150, 200))
	tim_label = _label("Tim ?", 13)
	panel_tim.add_child(tim_label)
	_update_tim_label()

	# panel Nusadex (overlay layar daftar + detail)
	dex_panel = PanelContainer.new()
	var st_dex := StyleBoxFlat.new()
	st_dex.bg_color = Color(0.08, 0.1, 0.12, 0.97)
	st_dex.set_corner_radius_all(10)
	dex_panel.add_theme_stylebox_override("panel", st_dex)
	dex_panel.position = Vector2(30, 24)
	dex_panel.custom_minimum_size = Vector2(840, 590)
	add_child(dex_panel)
	var vdex := VBoxContainer.new()
	dex_panel.add_child(vdex)
	dex_header = _label("", 15, Color(1.0, 0.9, 0.5))
	vdex.add_child(dex_header)
	var hdex := HBoxContainer.new()
	hdex.custom_minimum_size = Vector2(820, 480)
	vdex.add_child(hdex)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 480)
	hdex.add_child(scroll)
	dex_daftar = VBoxContainer.new()
	scroll.add_child(dex_daftar)
	dex_detail = RichTextLabel.new()
	dex_detail.custom_minimum_size = Vector2(510, 480)
	hdex.add_child(dex_detail)
	_tombol_menu("Kembali", vdex, _tutup_nusadex)
	dex_panel.visible = false


# ------------------------------------------------------------ alur battle

func _log(tek: String) -> void:
	log_label.text += tek + "\n"


func _mulai_battle_liar() -> void:
	# wild dari antrean encounter dunia (Fase 3 langkah 2) bila ada,
	# selain itu rol acak prototipe (battle langsung dari menu).
	var antrean := EncounterSystem.ambil_antrean()
	var id: int
	if not antrean.is_empty():
		id = int(antrean.get("spesies", 0))
	else:
		id = WILD_IDS[rng.randi_range(0, WILD_IDS.size() - 1)]
	var spesies := NusamonData.find_species(data, id)
	wild_detail = data["detailSpesies"][str(id)]
	var lv: int
	if not antrean.is_empty():
		lv = maxi(1, int(antrean.get("level", WILD_LEVEL_RANGE[0])))
	else:
		lv = rng.randi_range(WILD_LEVEL_RANGE[0], WILD_LEVEL_RANGE[1])
	wild = NusamonInstance.create(spesies, wild_detail, 0, lv)
	Nusadex.lihat(id)  # melihat wild → entri Nusadex (siluet + nama)
	percobaan_kabur = 0
	_siapkan_pemain()

	_mon_masuk(player, wild)
	_mon_masuk(wild, player)
	_log("Seekor %s liar muncul! (Lv.%d)" % [wild.display_name, wild.level])
	_update_bars()
	_perbarui_model()


# ------------------------------------------------------------ model 3D (tahap 2/3)

## Pasang pratinjau 3D (SubViewport + model .glb). Null & diam bila model belum ada.
func _pasang_pratinjau_3d(pos: Vector2, ukuran: Vector2, path: String) -> Node:
	if not ResourceLoader.exists(path):
		return null
	var paket: PackedScene = load(path)
	if paket == null:
		return null
	var svc := SubViewportContainer.new()
	svc.position = pos
	svc.custom_minimum_size = ukuran
	svc.stretch = true
	var sv := SubViewport.new()
	sv.transparent_bg = true
	svc.add_child(sv)
	var inst: Node3D = paket.instantiate()
	sv.add_child(inst)
	var kamera := Camera3D.new()
	kamera.position = Vector3(0, 1.4, 3.4)
	kamera.rotation_degrees.x = -14
	sv.add_child(kamera)
	var cahaya := DirectionalLight3D.new()
	cahaya.rotation_degrees = Vector3(-45, 30, 0)
	sv.add_child(cahaya)
	add_child(svc)
	return svc


## Segarkan pratinjau 3D wild & player (panggil saat battle mulai / ganti mon).
func _perbarui_model() -> void:
	if pratinjau_wild != null:
		pratinjau_wild.queue_free()
	if pratinjau_player != null:
		pratinjau_player.queue_free()
	pratinjau_wild = null
	pratinjau_player = null
	var path_wild := NusamonData.path_model(_nama_tahap(data, wild.id, wild.stage_index))
	pratinjau_wild = _pasang_pratinjau_3d(Vector2(400, 56), Vector2(220, 190), path_wild)
	var path_p := NusamonData.path_model(_nama_tahap(data, player.id, player.stage_index))
	pratinjau_player = _pasang_pratinjau_3d(Vector2(560, 452), Vector2(200, 165), path_p)


## Nama tahap aktif sebuah spesies (untuk path model).
func _nama_tahap(d: Dictionary, id: int, tahap: int) -> String:
	var sp := NusamonData.find_species(d, id)
	var tahapan: Array = sp.get("tahapan", [])
	if tahapan.is_empty():
		return ""
	return String(tahapan[clampi(tahap, 0, tahapan.size() - 1)].get("nama", ""))


func _update_bars() -> void:
	wild_nama.text = wild.display_name
	wild_lv.text = "Lv.%d  [%s]" % [wild.level, " / ".join(wild.types)]
	wild_hp.max_value = wild.max_hp
	wild_hp.value = wild.current_hp
	wild_status.text = "" if wild.status == "" else wild.status.to_upper()

	p_nama.text = player.display_name
	p_lv.text = "Lv.%d  [%s]" % [player.level, " / ".join(player.types)]
	p_hp.max_value = player.max_hp
	p_hp.value = player.current_hp
	p_hp_text.text = "HP %d/%d" % [player.current_hp, player.max_hp]
	p_status.text = "" if player.status == "" else player.status.to_upper()
	# Latihan (EV-lite): "Latihan 12/50" — stat dengan bonus 4:1 ditandai +
	var ringkas: Array = []
	for k in ["atk", "def", "spa", "spd", "spe"]:
		var poin := int(player.latihan.get(k, 0))
		if poin > 0:
			ringkas.append("%s+%d" % [k, int(floor(float(poin) / 4.0))])
	p_latihan.text = "Latihan %d/50%s" % [
		player.latihan_total,
		(" (" + ", ".join(ringkas) + ")") if ringkas != [] else ""]
	# progress EXP ke level berikutnya (kurva L^3)
	var butuh := ExpSystem.total_exp(player.level + 1) - ExpSystem.total_exp(player.level)
	var dapat := player.exp_total - ExpSystem.total_exp(player.level)
	p_exp.max_value = butuh
	p_exp.value = dapat
	_update_tim_label()


## Panel ringkasan tim: nama + level, mon aktif ditandai.
func _update_tim_label() -> void:
	var baris: Array = []
	for m in Tim.anggota:
		baris.append("%s Lv.%d%s" % [m.display_name, m.level, " ▸" if m == Tim.aktif() else ""])
	var isi := "\n".join(baris)
	tim_label.text = "Tim %d/6\n%s" % [Tim.jumlah(), isi if isi != "" else "—"]


func _semua_menu(mati: bool) -> void:
	for m in [menu_utama, menu_move, menu_ball, menu_toko, menu_ganti]:
		for c in m.get_children():
			if c is Button:
				(c as Button).disabled = mati


# ------------------------------------------------------------ giliran & serangan

func _pilih_move(idx: int) -> void:
	var id := String(player.move_ids[idx])
	if player.pp_move(id) <= 0:
		_log("PP %s habis! Pilih move lain." % id)
		return
	_tutup_sub_menu()
	var mv := BattleEngine.cari_move(moves_db, id)
	_kategori_terakhir = String(mv.get("kategori", "fisik"))  # untuk kunci Latihan
	_giliran(true, mv)


func _giliran(pemain_menyerang: bool, move: Dictionary) -> void:
	turn_aktif = true
	_semua_menu(true)
	var penyerang := player if pemain_menyerang else wild
	var bertahan := wild if pemain_menyerang else player
	var move_lawan := _move_acak_musuh()
	if pemain_menyerang:
		_eksekusi_giliran_duo(penyerang, move, bertahan, move_lawan)
	else:
		_eksekusi_giliran_duo(penyerang, move, bertahan, _move_pemain_acak())
	_update_bars()
	_semua_menu(false)
	_tutup_sub_menu()
	turn_aktif = false


func _move_pemain_acak() -> Dictionary:
	var tersedia: Array = []
	for id in player.move_ids:
		if player.pp_move(String(id)) > 0:
			tersedia.append(id)
	if tersedia.is_empty():
		return BattleEngine.SAMARAN  # semua PP habis
	var id := String(tersedia[rng.randi_range(0, tersedia.size() - 1)])
	return BattleEngine.cari_move(moves_db, id)


func _move_acak_musuh() -> Dictionary:
	var tersedia: Array = []
	for id in wild.move_ids:
		if wild.pp_move(String(id)) > 0:
			tersedia.append(id)
	if tersedia.is_empty():
		return BattleEngine.SAMARAN  # semua PP habis
	var id := String(tersedia[rng.randi_range(0, tersedia.size() - 1)])
	return BattleEngine.cari_move(moves_db, id)


func _eksekusi_giliran_duo(
		a: NusamonInstance, move_a: Dictionary,
		b: NusamonInstance, move_b: Dictionary) -> void:
	var urutan := BattleEngine.urutan_giliran(a, move_a, b, move_b)
	for p in urutan:
		if p.is_fainted():
			continue
		var target := b if p == a else a
		var mv := move_a if p == a else move_b
		p.pakai_move(String(mv.get("id", "")))  # PP berkurang walau meleset
		if _eksekusi_serang(p, target, mv):
			# efek lanjutan (status/buff/debuff/heal) hanya bila serangan kena
			_cek_efek_move(p, mv, target)
			# ability penyentuh fisik bertahan (Racun Alami/Serbuk Sari/Madu Manis)
			_cek_ability_sentuh(p, target, mv)
		_update_bars()
		if target.is_fainted():
			_log("%s pingsan!" % target.display_name)
			_akhir_battle(target == wild)
			return
	# fase akhir: efek status kedua sisi
	_fase_status(a)
	_fase_status(b)
	_update_bars()
	# status (luka bakar/racun) bisa memaksa pingsan di fase ini —
	# pastikan battle berakhir, jangan lanjut dengan mon yang sudah mati.
	if a.is_fainted():
		_akhir_battle(a == wild)
		return
	if b.is_fainted():
		_akhir_battle(b == wild)
		return


func _eksekusi_serang(penyerang: NusamonInstance, bertahan: NusamonInstance, mv: Dictionary) -> bool:
	# cek status sebelum menyerang: tidur / terpikat / kelumpuhan
	if penyerang.status == "tidur":
		_log("%s tidur nyenyak..." % penyerang.display_name)
		return false
	if penyerang.status == "terpikat" and rng.randf() < AbilityEngine.PELUANG_TERPIKAT_GAGAL:
		_log("%s terpikat — gagal menyerang!" % penyerang.display_name)
		return false
	if penyerang.status == "kelumpuhan" and rng.randf() < BattleEngine.PELUANG_LOMPAT_KELUMPUHAN:
		_log("%s lumpuh dan tidak bisa bergerak!" % penyerang.display_name)
		return false
	var hasil := BattleEngine.execute_move(penyerang, bertahan, mv, chart, rng)
	if hasil["missed"]:
		_log("%s menggunakan %s... tapi meleset!" % [
			penyerang.display_name, mv.get("nama", "?")])
		return false
	if AbilityEngine.refleks_hindar(bertahan, rng):
		_log("%s menghindar (Refleks Kilat)!" % bertahan.display_name)
		return false
	if mv.get("power", 0) <= 0:
		_log("%s menggunakan %s." % [penyerang.display_name, mv.get("nama", "?")])
		return true
	if float(hasil["eff"]) == 0.0:
		_log("Tidak berefek ke %s!" % bertahan.display_name)
		return false
	bertahan.take_damage(int(hasil["damage"]))
	var catatan := ""
	if bool(hasil["kritis"]):
		catatan += " (kritis!)"
	if float(hasil["eff"]) > 1.0:
		catatan += " Sangat efektif!"
	elif float(hasil["eff"]) < 1.0:
		catatan += " Kurang efektif..."
	_log("%s menggunakan %s → %s terkena %d damage%s" % [
		penyerang.display_name, mv.get("nama", "?"),
		bertahan.display_name, int(hasil["damage"]), catatan])
	return true


## Terapkan efekData move. Buff/heal menimpa PENGguna; debuff/status menimpa target.
func _cek_efek_move(pengguna: NusamonInstance, mv: Dictionary, target: NusamonInstance) -> void:
	var efek: Variant = mv.get("efekData")
	if efek == null or typeof(efek) != TYPE_DICTIONARY:
		return
	var jenis := String((efek as Dictionary).get("jenis", ""))
	var peluang := float((efek as Dictionary).get("peluang", 0.0))
	match jenis:
		"luka_bakar", "racun", "kelumpuhan", "tidur":
			if target.status == "" and rng.randf() < peluang:
				BattleEngine.terapkan_status(target, jenis, rng)
				_log("%s terkena status %s!" % [target.display_name, jenis])
		"debuff_atk":
			if rng.randf() < peluang:
				target.ubah_tahap_stat("atk", -1)
				_log("ATK %s turun!" % target.display_name)
		"buff_atk":
			if rng.randf() < peluang:
				pengguna.ubah_tahap_stat("atk", 1)
				_log("ATK %s naik!" % pengguna.display_name)
		"buff_def":
			if rng.randf() < peluang:
				pengguna.ubah_tahap_stat("def", 1)
				_log("DEF %s naik!" % pengguna.display_name)
		"heal_50":
			if rng.randf() < peluang:
				var pulih := maxi(1, int(floor(float(pengguna.max_hp) / 2.0)))
				pengguna.heal(pulih)
				_log("%s memulihkan %d HP!" % [pengguna.display_name, pulih])


## Ability penyentuh fisik: bertahan merespons penyerang (hanya move fisik).
func _cek_ability_sentuh(penyerang: NusamonInstance, bertahan: NusamonInstance, mv: Dictionary) -> void:
	if String(mv.get("kategori", "fisik")) != "fisik":
		return
	var pesan := AbilityEngine.sentuh_fisik(penyerang, bertahan, rng)
	if pesan != "":
		_log(pesan)


func _fase_status(mon: NusamonInstance) -> void:
	if mon.is_fainted():
		return
	var pesan := BattleEngine.akhir_giliran_status(mon, rng)
	if pesan != "":
		_log(pesan)
	var pesan_ability := AbilityEngine.akhir_giliran(mon)
	if pesan_ability != "":
		_log(pesan_ability)


## Ability saat mon masuk battle (Pelindung Karang / Tiruan Suara).
func _mon_masuk(m: NusamonInstance, lawan: NusamonInstance) -> void:
	var pesan := AbilityEngine.masuk_battle(m, lawan)
	if pesan != "":
		_log(pesan)


# ------------------------------------------------------------ akhir battle

func _akhir_battle(musuh_kalah: bool) -> void:
	_semua_menu(false)
	if musuh_kalah:
		var yield_base := int(wild_detail.get("baseExpYield", 55))
		var gain := ExpSystem.exp_gain(yield_base, wild.level, mode_trainer)  # ×1.5 trainer
		_log("%s dikalahkan!" % wild.display_name)
		var hasil := ExpSystem.add_exp(player, NusamonData.find_species(data, player.id),
			data["detailSpesies"][str(player.id)], gain)
		for p in hasil["messages"]:
			_log(p)
		# Latihan (EV-lite): +1 poin untuk stat utama yang dipakai (gameplay-depth §6)
		var stat_kunci := _stat_kunci_kemenangan()
		var diterima := player.tambah_latihan(stat_kunci, 1)
		if diterima > 0:
			_log("%s mendapat 1 poin Latihan %s (%d/50)." % [
				player.display_name, stat_kunci, player.latihan_total])
		if mode_trainer:
			idx_trainer += 1
			if idx_trainer < tim_trainer.size():
				_mon_trainer_berikutnya()
			else:
				_trainer_kalah()
			return
		_selesai(true)
	else:
		if mode_trainer:
			_log(String(trainer_data.get("dialog", {}).get("kalah_pemain", "")))
		_log("%s pingsan... pulang ke pusat pemulihan." % player.display_name)
		_selesai(false)


## Mon berikutnya tim gym leader maju (battle trainer — Fase 3 langkah 4).
func _mon_trainer_berikutnya() -> void:
	wild = tim_trainer[idx_trainer]
	wild_detail = data["detailSpesies"][str(wild.id)]
	Nusadex.lihat(wild.id)
	_log("%s mengirim %s! (Lv.%d)" % [
		String(trainer_data.get("nama", "?")), wild.display_name, wild.level])
	_mon_masuk(wild, player)
	_update_bars()
	_perbarui_model()
	_semua_menu(false)
	turn_aktif = false


## Seluruh tim leader kalah: dialog, hadiah uang, lencana (membuka gate dunia).
func _trainer_kalah() -> void:
	var dlg: Dictionary = trainer_data.get("dialog", {})
	_log(String(dlg.get("menang_pemain", "")))
	var hadiah := int(trainer_data.get("hadiah_uang", 0))
	Inventori.uang += hadiah
	_update_uang()
	if hadiah > 0:
		_log("Hadiah: Rp %d!" % hadiah)
	var lencana: Dictionary = trainer_data.get("lencana", {})
	Progres.tambah_lencana(int(lencana.get("id", 0)))
	Progres.tandai_kalah_trainer(String(trainer_data.get("id", "")))
	_log("Mendapat %s! (Lencana G%d — jalan berikutnya terbuka)" % [
		String(lencana.get("nama", "?")), int(lencana.get("id", 0))])
	_selesai(true, "menang vs trainer")


func _selesai(menang: bool, teks := "") -> void:
	turn_aktif = true
	_semua_menu(true)
	_log("— Battle selesai (%s) —" % (teks if teks != "" else ("menang" if menang else "kalah")))
	_log("Muat ulang scene untuk battle baru.")
	_auto_simpan()


func _kabur() -> void:
	if turn_aktif:
		return
	if mode_trainer:
		_log("Tidak bisa kabur dari battle trainer!")
		return
	if AbilityEngine.lawan_terkunci(wild.ability):
		_log("Tidak bisa kabur — %s terkunci Cengkeraman Kuat!" % player.display_name)
		return
	turn_aktif = true
	_semua_menu(true)
	percobaan_kabur += 1
	var hk := BattleEngine.coba_kabur(player, wild, percobaan_kabur, rng)
	var berhasil := bool(hk.get("berhasil", false))
	if berhasil:
		_log("Berhasil kabur dari %s!" % wild.display_name)
	else:
		_log("Gagal kabur! %s menyerang balik..." % wild.display_name)
		_eksekusi_serang(wild, player, _move_acak_musuh())
		_update_bars()
		if player.is_fainted():
			_log("%s pingsan! Pulang ke pusat pemulihan." % player.display_name)
			_selesai(false)
			return
	_semua_menu(false)
	turn_aktif = false


func _lempar_amukan(ball_id: String) -> void:
	if turn_aktif:
		return
	if mode_trainer:
		_log("Tidak bisa menangkap Nusamon milik %s!" % String(trainer_data.get("nama", "?")))
		return
	turn_aktif = true
	_semua_menu(true)
	_tutup_sub_menu()
	if not Inventori.pakai_item(ball_id):
		_log("Stok %s habis! Beli di TOKO." % ball_id)
		_semua_menu(false)
		turn_aktif = false
		return
	var rate := int(wild_detail.get("catchRate", 100))
	var hasil := CatchSystem.attempt_catch(wild, rate, ball_id, rng)
	var getar := int(hasil["shakes"])
	if bool(hasil["catch"]):
		if getar > 0:
			_log("Amukan bergetar %d kali..." % getar)
		Nusadex.tangkap(wild.id)
		if Tim.tambah(wild):
			_log("Berhasil! %s tertangkap dan masuk tim (%d/6)!" % [
				wild.display_name, Tim.jumlah()])
		else:
			_log("Berhasil! %s tertangkap... tapi tim penuh — dilepas kembali." % [
				wild.display_name])
		_update_tim_label()
		_selesai(true, "tertangkap")
		return
	if getar > 0:
		_log("Amukan bergetar %d kali... tapi %s berhasil keluar!" % [
			getar, wild.display_name])
	else:
		_log("Amukan langsung dilepas! %s berhasil keluar!" % wild.display_name)
	# musuh menyerang balik setelah gagal ditangkap
	_eksekusi_serang(wild, player, _move_acak_musuh())
	_update_bars()
	if player.is_fainted():
		_log("%s pingsan! Pulang ke pusat pemulihan." % player.display_name)
		_selesai(false)
		return
	_semua_menu(false)
	turn_aktif = false


## Stat utama kemenangan untuk poin Latihan: kategori move terakhir yang dipilih
## pemain (fisik → atk, spesial → spa); default atk.
static var _kategori_terakhir := "fisik"


func _stat_kunci_kemenangan() -> String:
	return "spa" if _kategori_terakhir == "spesial" else "atk"


# ------------------------------------------------------------ simpan/muat

func _tombol_simpan() -> void:
	if Simpanan.simpan():
		_log("Permainan tersimpan.")
	else:
		_log("Gagal menyimpan permainan!")


func _tombol_muat() -> void:
	if Simpanan.muat():
		_log("Permainan dimuat. Battle baru dimulai dengan state tersimpan.")
		_update_uang()
		_update_bars()
		_mulai_battle_liar()
	else:
		_log("Tidak ada save file / tidak kompatibel.")


## Auto-load saat scene siap (silent — bila ada save yang valid).
func _auto_muat() -> void:
	Simpanan.muat()


## Auto-save di akhir battle.
func _auto_simpan() -> void:
	Simpanan.simpan()


# ------------------------------------------------------------ toko

func _update_uang() -> void:
	uang_label.text = "Rp %d" % Inventori.uang


func _buka_menu_toko() -> void:
	if turn_aktif:
		return
	menu_utama.visible = false
	menu_move.visible = false
	menu_ball.visible = false
	menu_ganti.visible = false
	_bersihkan(menu_toko)
	var info := _label("Uang: Rp %d" % Inventori.uang, 14, Color(1.0, 0.9, 0.5))
	menu_toko.add_child(info)
	for it in Inventori.daftar_amukan():
		var iid: String = String(it.get("id", ""))
		var dijual: bool = bool(it.get("toko", false))
		var harga_item := Inventori.harga(iid)
		var teks: String
		if dijual:
			teks = "%s — Rp %d (stok %d)" % [
				String(it.get("nama", iid)), harga_item, Inventori.stok_item(iid)]
		else:
			teks = "%s — Hadiah Event" % String(it.get("nama", iid))
		var b := _tombol_menu(teks, menu_toko, func() -> void: _beli_item(iid))
		b.disabled = not dijual or Inventori.uang < harga_item
	# item jenis "latihan" (Teh Herba — reset Latihan mon aktif)
	for it2 in Inventori.items_jenis("latihan"):
		var iid2: String = String(it2.get("id", ""))
		var sisa2 := Inventori.stok_item(iid2)
		var teks2 := "%s — Rp %d (stok %d)" % [
			String(it2.get("nama", iid2)), Inventori.harga(iid2), sisa2]
		var b2 := _tombol_menu(teks2, menu_toko, func() -> void: _pakai_teh_herba(iid2))
		b2.disabled = sisa2 <= 0 or Inventori.uang < Inventori.harga(iid2)
	_tombol_menu("Kembali", menu_toko, _tutup_sub_menu)
	menu_toko.visible = true


func _beli_item(id: String) -> void:
	if Inventori.beli(id):
		_log("Dibeli 1 %s — stok %d, sisa Rp %d." % [
			id, Inventori.stok_item(id), Inventori.uang])
	else:
		_log("Tidak bisa membeli %s (uang kurang / tak dijual)." % id)
	_update_uang()
	_buka_menu_toko()  # perbarui tampilan uang/stok/disabled


## Teh Herba: reset semua poin Latihan mon aktif (gameplay-depth §6).
func _pakai_teh_herba(id: String) -> void:
	if not Inventori.pakai_item(id):
		_log("Stok %s habis!" % id)
		return
	var sebelum := player.latihan_total
	player.reset_latihan()
	_log("%s meminum Teh Herba — %d poin Latihan dihapus." % [player.display_name, sebelum])
	_update_bars()
	_buka_menu_toko()


# ------------------------------------------------------------ ganti mon

## Menu tukar Nusamon aktif (GDD §4.1). Ganti = satu giliran: lawan menyerang balik.
func _buka_menu_ganti() -> void:
	if turn_aktif:
		return
	menu_utama.visible = false
	menu_move.visible = false
	menu_ball.visible = false
	menu_toko.visible = false
	_bersihkan(menu_ganti)
	for i in Tim.jumlah():
		var m: NusamonInstance = Tim.anggota[i]
		var idx := i
		var tanda := " ▸" if m == Tim.aktif() else ""
		var b := _tombol_menu("%s%s Lv.%d — %d/%d" % [
			m.display_name, tanda, m.level, m.current_hp, m.max_hp],
			menu_ganti, func() -> void: _ganti_mon(idx))
		b.disabled = (m == Tim.aktif()) or m.is_fainted()
	_tombol_menu("Kembali", menu_ganti, _tutup_sub_menu)
	menu_ganti.visible = true


func _ganti_mon(idx: int) -> void:
	if turn_aktif:
		return
	if idx < 0 or idx >= Tim.jumlah():
		return
	var pilihan: NusamonInstance = Tim.anggota[idx]
	if pilihan == Tim.aktif():
		_log("%s sudah bertarung!" % pilihan.display_name)
		return
	if pilihan.is_fainted():
		_log("%s pingsan — tidak bisa bertarung." % pilihan.display_name)
		return
	if AbilityEngine.lawan_terkunci(wild.ability):
		_log("Tidak bisa ganti — %s terkunci Cengkeraman Kuat!" % wild.display_name)
		return
	turn_aktif = true
	_semua_menu(true)
	_tutup_sub_menu()
	var lama := Tim.aktif()
	Tim.ubah_aktif(idx)
	player = Tim.aktif()
	_log("Memanggil kembali %s... %s maju!" % [lama.display_name, player.display_name])
	_mon_masuk(player, wild)
	_perbarui_model()
	_update_bars()
	# ganti menghabiskan giliran: lawan menyerang balik sekali
	var mv := _move_acak_musuh()
	wild.pakai_move(String(mv.get("id", "")))
	_eksekusi_serang(wild, player, mv)
	_update_bars()
	if player.is_fainted():
		_log("%s pingsan!" % player.display_name)
		_selesai(false)
		return
	_semua_menu(false)
	turn_aktif = false


# ------------------------------------------------------------ nusadex

func _buka_nusadex() -> void:
	if turn_aktif:
		return
	_semua_menu(true)
	_tutup_sub_menu()
	_pembaruan_dex()
	dex_panel.visible = true


func _tutup_nusadex() -> void:
	dex_panel.visible = false
	_semua_menu(false)


## Bangun ulang daftar 30 entri + header progres.
func _pembaruan_dex() -> void:
	dex_header.text = "📖 Nusadex — %d/%d terlihat · %d/%d tertangkap" % [
		Nusadex.jumlah_lihat(), Nusadex.TOTAL, Nusadex.jumlah_tangkap(), Nusadex.TOTAL]
	_bersihkan(dex_daftar)
	for i in data["nusamons"].size():
		var sp: Dictionary = data["nusamons"][i]
		var id := int(sp.get("id", 0))
		var idx: int = i
		var teks: String
		if Nusadex.sudah_tangkap(id):
			teks = "#%02d %s ✓" % [id, String(sp.get("nama", "?"))]
		elif Nusadex.sudah_lihat(id):
			teks = "#%02d %s ◑" % [id, String(sp.get("nama", "?"))]
		else:
			teks = "#%02d ??????" % id
		var b := _tombol_menu(teks, dex_daftar, func() -> void: _pilih_dex(idx))
		(b as Button).alignment = HORIZONTAL_ALIGNMENT_LEFT


## Layar detail entri Nusadex (docs/nusadex.md §3.2).
func _pilih_dex(idx: int) -> void:
	var sp: Dictionary = data["nusamons"][idx]
	var id := int(sp.get("id", 0))
	var hab: Variant = data["habitatPulau"].get(str(id), "?")
	var habitat := "?"
	if typeof(hab) == TYPE_ARRAY:
		var daftar: Array = []
		for x in hab:
			daftar.append(str(x))
		habitat = ", ".join(daftar)
	else:
		habitat = str(hab)
	var tahapan: Array = sp.get("tahapan", [])
	var chain: Array = []
	for i in tahapan.size():
		var tahap: Dictionary = tahapan[i]
		var nama := String(tahap.get("nama", "?"))
		if tahap.get("lvEvolusi") != null:
			nama += " (Lv %d)" % int(tahap.get("lvEvolusi"))
		chain.append(nama)
	var teks := "#%02d %s\n\n" % [id, String(sp.get("nama", "?"))]
	if Nusadex.sudah_tangkap(id):
		var tipe_akhir: Array = tahapan[tahapan.size() - 1].get("tipe", [])
		teks += "Tipe: %s\n" % " / ".join(tipe_akhir)
		teks += "Rarity: %s · Habitat: %s\n" % [String(sp.get("rarity", "?")), habitat]
		teks += "Evolusi: %s\n\n" % " → ".join(chain)
		teks += "Deskripsi:\n%s" % String(sp.get("deskripsi", "—"))
	elif Nusadex.sudah_lihat(id):
		teks += "Terlihat di alam — belum tertangkap.\n\n"
		teks += "Evolusi: %s" % " → ".join(chain)
	else:
		teks += "Belum terlihat. Jelajahi habitatnya!"
	dex_detail.text = teks


func _bersihkan(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()


func _buka_menu_move() -> void:
	if turn_aktif:
		return
	menu_utama.visible = false
	menu_ball.visible = false
	menu_toko.visible = false
	menu_ganti.visible = false
	_bersihkan(menu_move)
	for i in player.move_ids.size():
		var mv := BattleEngine.cari_move(moves_db, String(player.move_ids[i]))
		var idx := i
		var pp := player.pp_move(String(mv.get("id", "")))
		var b := _tombol_menu("%s (%s) — PP %d" % [mv.get("nama", ""), mv.get("tipe", "?"), pp],
			menu_move, func() -> void: _pilih_move(idx))
		b.disabled = pp <= 0
	_tombol_menu("Kembali", menu_move, _tutup_sub_menu)
	menu_move.visible = true


func _buka_menu_ball() -> void:
	if turn_aktif:
		return
	menu_utama.visible = false
	menu_move.visible = false
	menu_toko.visible = false
	menu_ganti.visible = false
	_bersihkan(menu_ball)
	for it in Inventori.daftar_amukan():
		var bid: String = String(it.get("id", ""))
		var sisa := Inventori.stok_item(bid)
		var b := _tombol_menu("%s [stok %d]" % [String(it.get("nama", bid)), sisa],
			menu_ball, func() -> void: _lempar_amukan(bid))
		b.disabled = sisa <= 0
	_tombol_menu("Kembali", menu_ball, _tutup_sub_menu)
	menu_ball.visible = true


func _tutup_sub_menu() -> void:
	menu_move.visible = false
	menu_ball.visible = false
	menu_toko.visible = false
	menu_ganti.visible = false
	menu_utama.visible = true


## Buka peta dunia Jawa (Fase 3 langkah 1). State sesi (Tim/Inventori/Nusadex/
## Progres) bertahan karena static store — konvensi prototipe.
func _ke_dunia() -> void:
	get_tree().change_scene_to_file("res://game/world/world_scene.tscn")