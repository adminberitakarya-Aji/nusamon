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
var max_hp := 1
var current_hp := 1
var move_ids: Array = []
var ability := ""
var status := ""            # "", "luka_bakar", "racun", "kelumpuhan", "tidur"
var status_turn := 0        # penghitung untuk status berdurasi (tidur)
var exp_total := 0          # akumulasi EXP (kurva medium-fast: level^3)


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
	inst.stats = NusamonData.stats_for_stage(species, stage_index)
	inst.max_hp = _hitung_hp(int(inst.stats["hp"]), level)
	inst.current_hp = inst.max_hp
	inst.exp_total = level * level * level
	inst._ambil_moves(detail, level)
	return inst


static func _hitung_hp(base: int, level: int) -> int:
	return int(floor(2.0 * base * level / 100.0)) + level + 10


static func _hitung_stat(base: int, level: int) -> int:
	return int(floor(2.0 * base * level / 100.0)) + 5


## Ambil move dari learnset yang tersedia pada level tsb (maks. 4, yang terbaru).
func _ambil_moves(detail: Dictionary, level: int) -> void:
	var tercapai: Array = []
	for l in detail.get("learnset", []):
		if int(l.get("lv", 0)) <= level:
			tercapai.append(String(l.get("move", "")))
	while tercapai.size() > 4:
		tercapai.pop_front()
	move_ids = tercapai


func take_damage(nilai: int) -> void:
	current_hp = clampi(current_hp - nilai, 0, max_hp)


func heal(nilai: int) -> void:
	current_hp = clampi(current_hp + nilai, 0, max_hp)


func is_fainted() -> bool:
	return current_hp <= 0
