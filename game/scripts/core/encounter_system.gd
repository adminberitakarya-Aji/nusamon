class_name EncounterSystem
extends RefCounted
## Sistem encounter liar NUSAMON (static) — Fase 3 langkah 2.
## Sumber pool encounter (hybrid):
##   1. Tabel khas rute di data/world.json (field "encounters") — desain
##      per-rute dari docs/world-region.md §2.1.
##   2. Turunan habitat: spesies yang `habitatPulau`-nya mencakup pulau
##      lokasi, dibobot rarity (docs/gameplay-depth.md §4) — fallback untuk
##      lokasi tanpa tabel eksplisit (Fase 4/5).
## Starter & legendary TIDAK muncul liar (bobot 0 — gameplay-depth §4).
## Terpisah dari UI (konvensi engine lain) → testable headless, RNG injectable.

## Bobot kemunculan per rarity (docs/gameplay-depth.md §4).
## Legendary = event (bukan random); starter = tidak ada di alam.
const BOBOT_RARITY := {
	"common": 60,
	"uncommon": 25,
	"rare": 12,
	"pseudo_legendary": 3,
	"legendary": 0,
	"starter": 0,
}

## Antrean battle liar (handoff world scene → battle scene).
## Static store sesi — dikonsumsi sekali lalu kosong (ambil_antrean).
static var antrean_liar: Dictionary = {}


static func reset() -> void:
	antrean_liar = {}


## Bobot kemunculan sebuah rarity; 0 bila rarity tidak dikenal (gagal aman).
static func bobot_rarity(rarity: String) -> int:
	return int(BOBOT_RARITY.get(rarity, 0))


## Pool dari tabel khas lokasi (data/world.json "encounters").
## Entri: {spesies: int, bobot: int, level_min: int, level_max: int}.
static func pool_dari_tabel(lokasi: Dictionary) -> Array:
	var hasil: Array = []
	for e in lokasi.get("encounters", []):
		hasil.append({
			"spesies": int(e.get("spesies", 0)),
			"bobot": int(e.get("bobot", 0)),
			"level_min": int(e.get("level_min", 2)),
			"level_max": int(e.get("level_max", 6)),
		})
	return hasil


## Pool turunan habitat: semua spesies dengan bobot rarity > 0 yang
## habitatPulau-nya mencakup `pulau`. Entri seperti pool_dari_tabel.
static func pool_dari_habitat(nusamons: Dictionary, pulau: String,
		level_range: Array = [2, 6]) -> Array:
	var hasil: Array = []
	for sp in nusamons.get("nusamons", []):
		var id := int(sp.get("id", 0))
		var w := bobot_rarity(String(sp.get("rarity", "")))
		if w <= 0:
			continue
		if not habitat_valid(nusamons, pulau, id):
			continue
		hasil.append({
			"spesies": id,
			"bobot": w,
			"level_min": int(level_range[0]) if level_range.size() > 0 else 2,
			"level_max": int(level_range[1]) if level_range.size() > 1 else 6,
		})
	return hasil


## Spesies berhabitat di `pulau`? (habitatPulau = array nama pulau, data JSON).
static func habitat_valid(nusamons: Dictionary, pulau: String, spesies_id: int) -> bool:
	var hab: Variant = nusamons.get("habitatPulau", {}).get(str(spesies_id), null)
	if hab == null or typeof(hab) != TYPE_ARRAY:
		return false
	return hab.has(pulau)


## Pilih satu entri pool secara berbobot; {} bila pool kosong / bobot total 0.
static func pilih_spesies(pool: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total := 0
	for e in pool:
		total += maxi(0, int(e.get("bobot", 0)))
	if total <= 0:
		return {}
	var roll := rng.randi_range(0, total - 1)
	for e in pool:
		roll -= maxi(0, int(e.get("bobot", 0)))
		if roll < 0:
			return e
	return pool.back()


## Roll level dari entri pool (inklusif; min bila rentang tak valid).
static func pilih_level(entri: Dictionary, rng: RandomNumberGenerator) -> int:
	var lo := int(entri.get("level_min", 2))
	var hi := int(entri.get("level_max", lo))
	if hi < lo:
		return lo
	return rng.randi_range(lo, hi)


## Encounter lengkap dari tabel khas: {spesies, level} atau {}.
static func encounter_dari_tabel(lokasi: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var entri := pilih_spesies(pool_dari_tabel(lokasi), rng)
	if entri.is_empty():
		return {}
	return {"spesies": int(entri["spesies"]), "level": pilih_level(entri, rng)}


## Encounter lengkap dari pool habitat: {spesies, level} atau {}.
static func encounter_dari_habitat(nusamons: Dictionary, pulau: String,
		rng: RandomNumberGenerator, level_range: Array = [2, 6]) -> Dictionary:
	var entri := pilih_spesies(pool_dari_habitat(nusamons, pulau, level_range), rng)
	if entri.is_empty():
		return {}
	return {"spesies": int(entri["spesies"]), "level": pilih_level(entri, rng)}


## Apakah encounter terjadi di lokasi ini? (peluang data-driven per rute:
## field "peluang_encounter" 0..1 di world.json; lokasi tanpa field → tidak).
static func terjadi(lokasi: Dictionary, rng: RandomNumberGenerator) -> bool:
	var p := float(lokasi.get("peluang_encounter", 0.0))
	if p <= 0.0:
		return false
	if p >= 1.0:
		return true
	return rng.randf() < p


## Isi antrean battle liar (dipanggil world scene sebelum pindah ke battle).
static func set_antrean(spesies: int, level: int) -> void:
	antrean_liar = {"spesies": spesies, "level": level}


## Ambil & kosongkan antrean (dipanggil battle scene sekali saat mulai).
static func ambil_antrean() -> Dictionary:
	var hasil := antrean_liar
	antrean_liar = {}
	return hasil