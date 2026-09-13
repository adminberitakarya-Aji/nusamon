class_name NusamonInstance
extends RefCounted
## Instans Nusamon saat battle: data spesies + tahap + level → stat aktual.
## Rumus stat (tanpa IV, sesuai GDD §4.4):
##   HP   = floor(2 * base * level / 100) + level + 10
##   lain = floor(2 * base * level / 100) + 5

var id := 0
var display_name := ""
var types: Array = []
var level := 1
var stage_index := 0
var stats := {}
var stats_efektif := {}
var max_hp := 1
var current_hp := 1
var move_ids: Array = []
var ability := ""
var status := ""            # "", "luka_bakar", "racun", "kelumpuhan", "tidur", "terpikat"
var status_turn := 0        # penghitung untuk status berdurasi (tidur)
var exp_total := 0          # akumulasi EXP (kurva medium-fast: level^3)
var stat_stages := {}       # tahap stat battle: atk/def/spa/spd/spe -> -6..+6
var move_pp := {}           # sisa PP per move id (data moves.json: field "poin")
var latihan := {}           # EV-lite: poin per stat (gameplay-depth.md §6)
var latihan_total := 0      # total poin latihan (cap 50)


## Bangun instans dari data JSON.
## species = entri di data/nusamons.json (nusamons[i])
## detail  = entri di data/detailSpesies[id]
static func create(species: Dictionary, detail: Dictionary, stage_index: int, level: int) -> NusamonInstance:
	var tahapan: Array = species.get("tahapan", [])
	if stage_index < 0 or stage_index >= tahapan.size():
		push_error("NusamonInstance: stage_index di luar jangkauan")
		return null
	var inst := NusamonInstance.new()
	var tahap: Dictionary = tahapan[stage_index]
	inst.id = int(species.get("id", 0))
	inst.display_name = String(tahap.get("nama", "?"))
	inst.types = tahap.get("tipe", [])
	inst.level = level
	inst.stage_index = stage_index
	inst.ability = String(detail.get("ability", ""))
	var base_stats := NusamonData.stats_for_stage(species, stage_index)
	inst.max_hp = _hitung_hp(int(base_stats["hp"]), level)
	inst.stats = _stat_runtime(base_stats, level)
	inst.stats_efektif = inst.stats.duplicate()
	inst.latihan = {}
	inst.latihan_total = 0
	inst.current_hp = inst.max_hp
	inst.exp_total = level * level * level
	inst.stat_stages = {"atk": 0, "def": 0, "spa": 0, "spd": 0, "spe": 0}
	inst._ambil_moves(detail, level)
	return inst


static func _hitung_hp(base: int, level: int) -> int:
	return int(floor(2.0 * base * level / 100.0)) + level + 10


static func _hitung_stat(base: int, level: int) -> int:
	return int(floor(2.0 * base * level / 100.0)) + 5


## Konversi base stats (hasil skala tahap) → stat runtime pada level tertentu.
## Kunci "hp" sengaja tetap base — nilai HP runtime tersimpan di max_hp
## (rumus _hitung_hp), dan base hp dipakai ulang saat evolusi (exp_system._evolve).
static func _stat_runtime(base_stats: Dictionary, level: int) -> Dictionary:
	var hasil := {}
	for k in base_stats:
		if k == "hp":
			hasil[k] = int(base_stats[k])
		else:
			hasil[k] = _hitung_stat(int(base_stats[k]), level)
	return hasil


## Konstanta Latihan (EV-lite, gameplay-depth.md §6).
const LATIHAN_CAP_TOTAL := 50
const LATIHAN_CAP_STAT := 25
const LATIHAN_POIN_PER_STAT := 4


## Ambil move dari learnset yang tersedia pada level tsb (maks. 4, yang terbaru)
## dan isi PP penuh dari data moves.json (field "poin").
func _ambil_moves(detail: Dictionary, level: int, moves_db: Dictionary = {}) -> void:
	var tercapai: Array = []
	for l in detail.get("learnset", []):
		if int(l.get("lv", 0)) <= level:
			tercapai.append(String(l.get("move", "")))
	while tercapai.size() > 4:
		tercapai.pop_front()
	move_ids = tercapai
	var db := moves_db
	if db.is_empty():
		db = NusamonData.load_moves()
	move_pp.clear()
	for id in move_ids:
		for mv in db.get("moves", []):
			if String(mv.get("id", "")) == String(id):
				move_pp[String(id)] = int(mv.get("poin", 10))
				break


func take_damage(nilai: int) -> void:
	current_hp = clampi(current_hp - nilai, 0, max_hp)


func heal(nilai: int) -> void:
	current_hp = clampi(current_hp + nilai, 0, max_hp)


func is_fainted() -> bool:
	return current_hp <= 0


## Ubah tahap stat battle (mis. +1 buff_atk). Dibatasi -6..+6 (konvensi Pokémon).
## Mengembalikan jumlah tahap yang benar-benar terpakai.
func ubah_tahap_stat(kunci: String, delta: int) -> int:
	var sekarang := int(stat_stages.get(kunci, 0))
	var baru := clampi(sekarang + delta, -6, 6)
	stat_stages[kunci] = baru
	return baru - sekarang


## Kurangi PP 1; false bila PP sudah 0. Move tanpa data PP (mis. Meronta) selalu bisa.
func pakai_move(id: String) -> bool:
	if not move_pp.has(id):
		return true
	if int(move_pp[id]) <= 0:
		return false
	move_pp[id] = int(move_pp[id]) - 1
	return true


func pp_move(id: String) -> int:
	return int(move_pp.get(id, 0))


# ------------------------------------------------------------ latihan (EV-lite)

## Tambah poin latihan ke `kunci` (atk/def/spa/spd/spe).
## Batas: total 50 per mon, maks. 25 per stat (gameplay-depth.md §6).
## Mengembalikan jumlah poin yang benar-benar diterima.
func tambah_latihan(kunci: String, n := 1) -> int:
	if not stat_stages.has(kunci):
		return 0
	var diterima := 0
	for i in n:
		if latihan_total >= LATIHAN_CAP_TOTAL:
			break
		if int(latihan.get(kunci, 0)) >= LATIHAN_CAP_STAT:
			break
		latihan[kunci] = int(latihan.get(kunci, 0)) + 1
		latihan_total += 1
		diterima += 1
	if diterima > 0:
		_hitung_stat_efektif()
	return diterima


## Item "Teh Herba": hapus semua poin latihan (strategi bisa diubah ulang).
func reset_latihan() -> void:
	latihan = {}
	latihan_total = 0
	_hitung_stat_efektif()


## Stat runtime efektif = rumus level + bonus latihan (4 poin = +1 stat).
## Latihan dipakai dalam damage — stats dasar tetap dipertahankan (bersih untuk save).
func _hitung_stat_efektif() -> void:
	for k in stats:
		if k == "hp":
			continue
		var bonus := int(floor(float(int(latihan.get(k, 0))) / 4.0))
		stats_efektif[k] = int(stats[k]) + bonus


## Kembalikan dict latihan yang aman untuk save (subset kunci stat saja).
func latihan_untuk_save() -> Dictionary:
	var hasil := {}
	for k in latihan:
		if stat_stages.has(k):
			hasil[k] = int(latihan[k])
	return hasil
