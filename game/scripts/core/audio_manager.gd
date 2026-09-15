class_name AudioManager
extends RefCounted
## AudioManager NUSAMON (static) — Fase 5 langkah 5.
## Data: data/audio.json (SSOT id/file/volume) via NusamonData.load_audio().
## Konvensi static store (seperti Inventori/Progres) → testable headless:
## player node dibuat & dilampirkan ke root SceneTree saat pertama dipakai.
## Bus: Master (default) + Music (BGM/jingle/sting) + SFX (efek pendek).
## Placeholder = .wav "gamelan-ambient" terprogram (tools/audio/generate_sfx.py);
## ganti file asli (CC0/.ogg) tanpa ubah kode — id & path di data/audio.json.

const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const MAX_SFX := 6   # batasi voice sfx simultan

static var _siap := false
static var bgm_aktif := ""                 # id BGM yang sedang berbunyi; "" = senyap
static var _musik: AudioStreamPlayer = null
static var _sfx_aktif: Array = []
static var _cache_stream := {}
static var volume_musik := 0.8             # faktor pengali bus Music (0..1)
static var volume_sfx := 0.9


# ------------------------------------------------------------ setup

## Pastikan bus & player siap (idempoten; aman dipanggil berulang).
## add_child pakai call_deferred — bila dipanggil dari _ready() scene, root
## sedang busy setup children dan add_child sinkron ditolak engine.
static func pastikan_siap() -> void:
	if _siap:
		return
	_buat_bus(BUS_MUSIC)
	_buat_bus(BUS_SFX)
	var root := _root()
	if root != null:
		_musik = AudioStreamPlayer.new()
		_musik.name = "AudioManagerMusic"
		_musik.bus = BUS_MUSIC
		root.add_child.call_deferred(_musik)
	_siap = true


static func _root() -> Node:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return (loop as SceneTree).root
	return null


static func _buat_bus(nama: String) -> void:
	if AudioServer.get_bus_index(nama) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, nama)
		AudioServer.set_bus_send(idx, "Master")
		AudioServer.set_bus_volume_db(idx, linear_to_db(1.0))
		AudioServer.set_bus_mute(idx, false)


## Kembalikan ke kondisi awal (prototipe/tes) — hentikan bunyi, kosongkan cache.
static func reset() -> void:
	stop_bgm()
	for p in _sfx_aktif:
		if is_instance_valid(p):
			p.queue_free()
	_sfx_aktif = []
	_cache_stream = {}
	_siap = false
	volume_musik = 0.8
	volume_sfx = 0.9


# ------------------------------------------------------------ data & stream

static func _db() -> Dictionary:
	if _cache_stream.has("__db"):
		return _cache_stream["__db"]
	var db := NusamonData.load_audio()
	_cache_stream["__db"] = db
	return db


## Cari entri lagu (bgm/jingle/sting) atau sfx berdasarkan id; {} bila tak dikenal.
static func cari_entri(id: String) -> Dictionary:
	var db := _db()
	for l in db.get("lagu", []):
		if String(l.get("id", "")) == id:
			return l
	for s in db.get("sfx", []):
		if String(s.get("id", "")) == id:
			return s
	return {}


static func _muat_stream(entri: Dictionary) -> AudioStream:
	var path := String(entri.get("file", ""))
	if path == "" or not ResourceLoader.exists(path):
		return null   # fail-safe: file hilang → senyap, game jalan
	var stream: AudioStream = load(path)
	if stream == null:
		return null
	# loop BGM (placeholder .wav diset runtime; .ogg asli ikut properti ini)
	if bool(entri.get("loop", false)) and stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_end = -1
	return stream


# ------------------------------------------------------------ BGM / jingle / sting

## Mulai/ganti BGM dengan crossfade sederhana; false bila id tak dikenal.
static func ganti_bgm(id: String, fade := 0.8) -> bool:
	var entri := cari_entri(id)
	if entri.is_empty() or String(entri.get("jenis", "")) != "bgm":
		return false
	if id == bgm_aktif:
		return true   # sudah berbunyi — jangan restart (jaga loop)
	pastikan_siap()
	if _musik == null:
		return false
	var stream := _muat_stream(entri)
	if stream == null:
		return false
	var vol := linear_to_db(maxf(0.01, float(entri.get("volume", 0.5)) * volume_musik))
	if not _musik.is_inside_tree():
		# player menunggu deferred-add (dipanggil dari _ready scene) —
		# jadwalkan play saat node resmi masuk tree
		_musik.stream = stream
		_musik.volume_db = vol
		_musik.tree_entered.connect(_musik.play, CONNECT_ONE_SHOT)
	elif _musik.playing and fade > 0.0:
		var tw := _musik.create_tween()
		tw.tween_property(_musik, "volume_db", -40.0, fade * 0.5)
		tw.tween_callback(func() -> void:
			_musik.stream = stream
			_musik.volume_db = linear_to_db(maxf(0.01, float(entri.get("volume", 0.5)) * volume_musik * 0.2))
			_musik.play())
		tw.tween_property(_musik, "volume_db", vol, fade * 0.5)
	else:
		_musik.stream = stream
		_musik.volume_db = vol
		_musik.play()
	bgm_aktif = id
	return true


## Putar jingle/sting sekali DI ATAS BGM (BGM tetap berbunyi).
static func mainkan_jingle(id: String) -> bool:
	var entri := cari_entri(id)
	if entri.is_empty() or String(entri.get("jenis", "")) == "sfx":
		return false
	pastikan_siap()
	var stream := _muat_stream(entri)
	var root := _root()
	if stream == null or root == null:
		return false
	var p := AudioStreamPlayer.new()
	p.name = "AudioManagerJingle_" + id
	p.bus = BUS_MUSIC
	p.stream = stream
	p.volume_db = linear_to_db(maxf(0.01, float(entri.get("volume", 0.6)) * volume_musik))
	root.add_child.call_deferred(p)
	p.tree_entered.connect(p.play, CONNECT_ONE_SHOT)
	p.finished.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free())
	return true


## Hentikan BGM (tes / scene tanpa musik).
static func stop_bgm() -> void:
	bgm_aktif = ""
	if _musik != null and is_instance_valid(_musik):
		_musik.stop()


# ------------------------------------------------------------ SFX

## Putar SFX sekali (voice dibatasi MAX_SFX); false bila id tak dikenal/file hilang.
static func mainkan_sfx(id: String) -> bool:
	var entri := cari_entri(id)
	if entri.is_empty() or String(entri.get("jenis", "")) != "sfx":
		return false
	pastikan_siap()
	_sfx_aktif = _sfx_aktif.filter(func(p) -> bool: return is_instance_valid(p)
		and not p.is_queued_for_deletion())
	if _sfx_aktif.size() >= MAX_SFX:
		return true   # full voice — lewati senyap (tanpa antri)
	var stream := _muat_stream(entri)
	var root := _root()
	if stream == null or root == null:
		return false
	var p := AudioStreamPlayer.new()
	p.name = "AudioManagerSfx_" + id
	p.bus = BUS_SFX
	p.stream = stream
	p.volume_db = linear_to_db(maxf(0.01, float(entri.get("volume", 0.7)) * volume_sfx))
	root.add_child.call_deferred(p)
	p.tree_entered.connect(p.play, CONNECT_ONE_SHOT)
	_sfx_aktif.append(p)
	p.finished.connect(func() -> void:
		if is_instance_valid(p):
			p.queue_free())
	return true


# ------------------------------------------------------------ volume (opsi pengaturan)

static func atur_volume_musik(v: float) -> void:
	volume_musik = clampf(v, 0.0, 1.0)
	if AudioServer.get_bus_index(BUS_MUSIC) != -1:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC),
			linear_to_db(maxf(0.01, volume_musik)))


static func atur_volume_sfx(v: float) -> void:
	volume_sfx = clampf(v, 0.0, 1.0)
	if AudioServer.get_bus_index(BUS_SFX) != -1:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX),
			linear_to_db(maxf(0.01, volume_sfx)))
