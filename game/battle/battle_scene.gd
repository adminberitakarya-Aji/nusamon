extends Control
## Battle scene prototipe NUSAMON — UI dibangun programatik.
## Pemakaian: jalankan proyek (scene utama) → battle vs Nusamon liar.
## Sistem aktif: serang (4 move, PP), tahap stat (buff/debuff/heal), status,
## Amukan (4 jenis), kabur, EXP, evolusi.

const WILD_IDS := [22, 23, 24]          # rusa, monyet, ayam (Common — Jawa)
const WILD_LEVEL_RANGE := [2, 6]
const PLAYER_ID := 1                    # anak rimau (sebelum starter selection)
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


func _ready() -> void:
	rng.randomize()
	data = NusamonData.load_nusamons()
	chart = NusamonData.load_type_chart()
	moves_db = NusamonData.load_moves()
	if data.is_empty() or chart.is_empty() or moves_db.is_empty():
		push_error("BattleScene: data game gagal dimuat")
		return
	_bangun_ui()
	_mulai_battle_liar()


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
	p_exp = _hp_bar(Color(0.35, 0.55, 0.95))
	p_exp.custom_minimum_size = Vector2(240, 8)
	p_exp.max_value = 1
	vp.add_child(p_nama)
	vp.add_child(p_lv)
	vp.add_child(p_hp)
	vp.add_child(p_hp_text)
	vp.add_child(p_status)
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
	_tombol_menu("🏃 KABUR", menu_utama, _kabur)

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


# ------------------------------------------------------------ alur battle

func _log(tek: String) -> void:
	log_label.text += tek + "\n"


func _mulai_battle_liar() -> void:
	var id: int = WILD_IDS[rng.randi_range(0, WILD_IDS.size() - 1)]
	var spesies := NusamonData.find_species(data, id)
	wild_detail = data["detailSpesies"][str(id)]
	var lv := rng.randi_range(WILD_LEVEL_RANGE[0], WILD_LEVEL_RANGE[1])
	wild = NusamonInstance.create(spesies, wild_detail, 0, lv)

	var spesies_p := NusamonData.find_species(data, PLAYER_ID)
	player = NusamonInstance.create(
		spesies_p, data["detailSpesies"][str(PLAYER_ID)], 0, PLAYER_LEVEL)

	_log("Seekor %s liar muncul! (Lv.%d)" % [wild.display_name, wild.level])
	_update_bars()


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
	# progress EXP ke level berikutnya (kurva L^3)
	var butuh := ExpSystem.total_exp(player.level + 1) - ExpSystem.total_exp(player.level)
	var dapat := player.exp_total - ExpSystem.total_exp(player.level)
	p_exp.max_value = butuh
	p_exp.value = dapat


func _semua_menu(mati: bool) -> void:
	for m in [menu_utama, menu_move, menu_ball]:
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
	# cek tidur / kelumpuhan sebelum menyerang
	if penyerang.status == "tidur":
		_log("%s tidur nyenyak..." % penyerang.display_name)
		return false
	if penyerang.status == "kelumpuhan" and rng.randf() < BattleEngine.PELUANG_LOMPAT_KELUMPUHAN:
		_log("%s lumpuh dan tidak bisa bergerak!" % penyerang.display_name)
		return false
	var hasil := BattleEngine.execute_move(penyerang, bertahan, mv, chart, rng)
	if hasil["missed"]:
		_log("%s menggunakan %s... tapi meleset!" % [
			penyerang.display_name, mv.get("nama", "?")])
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


func _fase_status(mon: NusamonInstance) -> void:
	if mon.is_fainted():
		return
	var pesan := BattleEngine.akhir_giliran_status(mon, rng)
	if pesan != "":
		_log(pesan)


# ------------------------------------------------------------ akhir battle

func _akhir_battle(musuh_kalah: bool) -> void:
	_semua_menu(false)
	if musuh_kalah:
		var yield_base := int(wild_detail.get("baseExpYield", 55))
		var gain := ExpSystem.exp_gain(yield_base, wild.level)
		_log("%s dikalahkan!" % wild.display_name)
		var hasil := ExpSystem.add_exp(player, NusamonData.find_species(data, player.id),
			data["detailSpesies"][str(player.id)], gain)
		for p in hasil["messages"]:
			_log(p)
		_selesai(true)
	else:
		_log("%s pingsan... pulang ke pusat pemulihan." % player.display_name)
		_selesai(false)


func _selesai(menang: bool, teks := "") -> void:
	turn_aktif = true
	_semua_menu(true)
	_log("— Battle selesai (%s) —" % (teks if teks != "" else ("menang" if menang else "kalah")))
	_log("Muat ulang scene untuk battle baru.")


func _kabur() -> void:
	if turn_aktif:
		return
	turn_aktif = true
	_semua_menu(true)
	var berhasil := rng.randf() < 0.6
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
	turn_aktif = true
	_semua_menu(true)
	_tutup_sub_menu()
	var rate := int(wild_detail.get("catchRate", 100))
	var hasil := CatchSystem.attempt_catch(wild, rate, ball_id, rng)
	var getar := int(hasil["shakes"])
	if bool(hasil["catch"]):
		if getar > 0:
			_log("Amukan bergetar %d kali..." % getar)
		_log("Berhasil! %s tertangkap!" % wild.display_name)
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


func _bersihkan(n: Node) -> void:
	for c in n.get_children():
		c.queue_free()


func _buka_menu_move() -> void:
	if turn_aktif:
		return
	menu_utama.visible = false
	menu_ball.visible = false
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
	_bersihkan(menu_ball)
	for ball_id in CatchSystem.BALL_BONUS:
		var bid: String = String(ball_id)
		_tombol_menu(String(ball_id).capitalize(), menu_ball,
			func() -> void: _lempar_amukan(bid))
	_tombol_menu("Kembali", menu_ball, _tutup_sub_menu)
	menu_ball.visible = true


func _tutup_sub_menu() -> void:
	menu_move.visible = false
	menu_ball.visible = false
	menu_utama.visible = true