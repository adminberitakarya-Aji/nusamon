class_name ExpSystem
extends RefCounted
## Sistem EXP & evolusi (GDD §4.4–4.5, gameplay-depth §5):
##   Total EXP untuk mencapai level L = L^3 (medium-fast)
##   Gain per kemenangan = floor(baseExpYield * levelLawan / 7) * (1.5 trainer / 1.0 wild)

const MAX_LEVEL := 100
const TRAINER_MULTIPLIER := 1.5


## Total EXP untuk mencapai `level`.
static func total_exp(level: int) -> int:
	return level * level * level


## EXP diperoleh dari mengalahkan `level_lawan`.
static func exp_gain(base_exp_yield: int, level_lawan: int, is_trainer := false) -> int:
	var dasar := int(floor(float(base_exp_yield * level_lawan) / 7.0))
	var mult := TRAINER_MULTIPLIER if is_trainer else 1.0
	return int(floor(float(dasar) * mult))


## Tambah EXP → naik level → picu evolusi bila mencapai lvEvolusi tahap berikutnya.
## Mengembalikan {levels_gained, evolution: {nama, stage_index} | null, messages: Array}.
static func add_exp(
		inst: NusamonInstance, species: Dictionary, detail: Dictionary,
		amount: int) -> Dictionary:
	var hasil := {"levels_gained": 0, "evolution": null, "messages": []}
	var tahapan: Array = species.get("tahapan", [])
	var lv := inst.level
	var lv_awal := lv

	inst.exp_total += amount
	hasil["messages"].append("%s mendapat %d EXP!" % [inst.display_name, amount])

	while lv < MAX_LEVEL and inst.exp_total >= total_exp(lv + 1):
		lv += 1
		inst.level = lv
		hasil["levels_gained"] += 1
		hasil["messages"].append("%s naik ke Level %d!" % [inst.display_name, lv])
		# refresh move yang tersedia di level baru
		inst._ambil_moves(detail, lv)
		# evolusi bila level mencapai lvEvolusi tahap berikutnya
		var stage := inst.stage_index
		if stage + 1 < tahapan.size():
			var lv_evo := int(tahapan[stage + 1].get("lvEvolusi", 999999))
			if lv >= lv_evo:
				_evolve(inst, species, detail)
				var tahap_baru: Dictionary = tahapan[inst.stage_index]
				hasil["evolution"] = {
					"nama": String(tahap_baru.get("nama", "?")),
					"stage_index": inst.stage_index,
				}
				hasil["messages"].append("Wow! %s berevolusi menjadi %s!" % [
					String(tahapan[stage].get("nama", "?")),
					inst.display_name,
				])
	# sinkronkan level (jaga jikalau MAX_LEVEL)
	inst.level = lv
	hasil["levels_gained"] = lv - lv_awal
	return hasil


## Evolusi satu tahap: ganti identitas, hitung ulang stat, bonus HP (gameplay-depth §5).
static func _evolve(
		inst: NusamonInstance, species: Dictionary, detail: Dictionary) -> void:
	var tahapan: Array = species.get("tahapan", [])
	var stage := inst.stage_index + 1
	if stage >= tahapan.size():
		return
	var tahap: Dictionary = tahapan[stage]
	var old_max := inst.max_hp
	inst.stage_index = stage
	inst.display_name = String(tahap.get("nama", inst.display_name))
	inst.types = tahap.get("tipe", inst.types)
	inst.stats = NusamonData.stats_for_stage(species, stage)
	inst.max_hp = NusamonInstance._hitung_hp(int(inst.stats["hp"]), inst.level)
	inst.current_hp = clampi(inst.current_hp + (inst.max_hp - old_max), 0, inst.max_hp)
	inst._ambil_moves(detail, inst.level)
