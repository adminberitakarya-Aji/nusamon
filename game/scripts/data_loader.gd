class_name NusamonData
extends RefCounted
## Loader data game NUSAMON — membaca data/*.json (single source of truth).
## Pemakaian:
##   var data := NusamonData.load_nusamons()
##   var eff := NusamonData.effectiveness(chart, "Air", "Api")  # -> 2.0

const TYPE_CHART_PATH := "res://data/type-chart.json"
const NUSAMONS_PATH := "res://data/nusamons.json"
const MOVES_PATH := "res://data/moves.json"
const ITEMS_PATH := "res://data/items.json"


static func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("NusamonData: gagal membuka file: " + path)
		return {}
	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("NusamonData: JSON tidak valid: " + path)
		return {}
	return parsed as Dictionary


static func load_type_chart() -> Dictionary:
	return _read_json(TYPE_CHART_PATH)


static func load_nusamons() -> Dictionary:
	return _read_json(NUSAMONS_PATH)


static func load_moves() -> Dictionary:
	return _read_json(MOVES_PATH)


static func load_items() -> Dictionary:
	return _read_json(ITEMS_PATH)


## Efektivitas tipe penyerang -> pertahanan (default 1.0 jika tidak ada di chart).
static func effectiveness(chart: Dictionary, attacker: String, defender: String) -> float:
	var efektivitas: Dictionary = chart.get("efektivitas", {})
	var baris: Dictionary = efektivitas.get(attacker, {})
	return float(baris.get(defender, 1.0))


## Efektivitas multi-tipe pertahanan: kalikan semua kolom (dual-type).
static func effectiveness_multi(chart: Dictionary, attacker: String, defenders: Array) -> float:
	var total := 1.0
	for d in defenders:
		total *= effectiveness(chart, attacker, String(d))
	return total


## Base stats tahap tertentu = baseStatsFinal x skala (min 1).
static func stats_for_stage(species: Dictionary, stage_index: int) -> Dictionary:
	var tahapan: Array = species.get("tahapan", [])
	if stage_index < 0 or stage_index >= tahapan.size():
		push_error("NusamonData: stage_index di luar jangkauan")
		return {}
	var skala := float(tahapan[stage_index].get("skala", 1.0))
	var final_stats: Dictionary = species.get("baseStatsFinal", {})
	var hasil := {}
	for k in final_stats:
		hasil[k] = maxi(1, ceili(float(final_stats[k]) * skala))
	return hasil


## Cari spesies berdasarkan id (int).
static func find_species(db: Dictionary, id: int) -> Dictionary:
	for sp in db.get("nusamons", []):
		if int(sp.get("id", -1)) == id:
			return sp
	return {}
