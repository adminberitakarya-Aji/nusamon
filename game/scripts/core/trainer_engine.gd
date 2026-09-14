class_name TrainerEngine
extends RefCounted
## Engine trainer/gym NUSAMON (static) — Fase 3 langkah 3.
## Data: data/trainers.json (single source of truth) via NusamonData.load_trainers().
## Terpisah dari UI (konvensi engine lain) → testable headless.
## Orkestrasi battle trainer (multi-mon, urutan dialog, hadiah/lencana)
## = langkah 4 Fase 3; engine ini menyediakan data & pembuatan timnya.


## Cari trainer berdasarkan id; {} bila tidak dikenal.
static func cari(db: Dictionary, id: String) -> Dictionary:
	for t in db.get("trainers", []):
		if String(t.get("id", "")) == id:
			return t
	return {}


## Trainer gym yang menempati sebuah kota (gym.kota == id lokasi); {} bila kosong.
static func trainer_di_kota(db: Dictionary, kota_id: String) -> Dictionary:
	for t in db.get("trainers", []):
		var gym: Dictionary = t.get("gym", {})
		if String(gym.get("kota", "")) == kota_id:
			return t
	return {}


## Bangun tim NusamonInstance sesuai urutan data (orde dikirim saat battle).
## Bila trainer/spesies tidak dikenal → array kosong.
static func buat_tim(db: Dictionary, id: String, nusamons: Dictionary) -> Array:
	var t := cari(db, id)
	if t.is_empty():
		return []
	var hasil: Array = []
	for e in t.get("tim", []):
		var sid := int(e.get("spesies", 0))
		var spesies := NusamonData.find_species(nusamons, sid)
		if spesies.is_empty():
			push_error("TrainerEngine: spesies %d tidak dikenal (trainer %s)" % [sid, id])
			continue
		var detail: Dictionary = nusamons.get("detailSpesies", {}).get(str(sid), {})
		var mon := NusamonInstance.create(spesies, detail, 0, int(e.get("level", 1)))
		if mon != null:
			hasil.append(mon)
	return hasil


## Teks pratinjau tim untuk UI: "Monyet Kecil Lv.8 · Ayam Jantan Lv.10".
static func tim_teks(db: Dictionary, id: String, nusamons: Dictionary) -> String:
	var t := cari(db, id)
	if t.is_empty():
		return ""
	var bagian: Array = []
	for e in t.get("tim", []):
		var sp := NusamonData.find_species(nusamons, int(e.get("spesies", 0)))
		var tahapan: Array = sp.get("tahapan", [])
		var nama := "?"
		if not tahapan.is_empty():
			nama = String(tahapan[0].get("nama", "?"))
		bagian.append("%s Lv.%d" % [nama, int(e.get("level", 0))])
	return " · ".join(bagian)


## Data lencana trainer; {} bila tidak ada.
static func lencana(db: Dictionary, id: String) -> Dictionary:
	var t := cari(db, id)
	if t.is_empty():
		return {}
	var l: Variant = t.get("lencana")
	if l == null or typeof(l) != TYPE_DICTIONARY:
		return {}
	return l