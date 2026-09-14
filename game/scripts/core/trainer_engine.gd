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
## Entri tim: {spesies, level, tahap?, counter_starter?}.
## - counter_starter: true → spesies = starter lawan tipe (rival), di-resolve
##   dari Progres.starter_id (Api→Air, Daun→Api, Air→Daun — konvensi genre).
## Bila trainer/spesies tidak dikenal → array kosong.
static func buat_tim(db: Dictionary, id: String, nusamons: Dictionary) -> Array:
	var t := cari(db, id)
	if t.is_empty():
		return []
	var hasil: Array = []
	for e in t.get("tim", []):
		var sid := int(e.get("spesies", 0))
		var tahap := int(e.get("tahap", 0))
		if bool(e.get("counter_starter", false)):
			sid = starter_lawan(Progres.starter_id)
		var spesies := NusamonData.find_species(nusamons, sid)
		if spesies.is_empty():
			push_error("TrainerEngine: spesies %d tidak dikenal (trainer %s)" % [sid, id])
			continue
		var detail: Dictionary = nusamons.get("detailSpesies", {}).get(str(sid), {})
		var mon := NusamonInstance.create(
			spesies, detail, tahap, int(e.get("level", 1)))
		if mon != null:
			hasil.append(mon)
	return hasil


## Starter yang unggul tipe atas starter pemain (konvensi genre):
## Rimau (Api) → Penyuci (Air); Orangutan (Daun) → Rimau (Api); Penyu (Air) → Orangutan (Daun).
const STARTER_COUNTER := {1: 3, 2: 1, 3: 2}


static func starter_lawan(starter_id: int) -> int:
	return int(STARTER_COUNTER.get(starter_id, 3))   # fallback aman: Penyuci (Air)


## Teks pratinjau tim untuk UI: "Monyet Kecil Lv.8 · Ayam Satria Lv.16"
## (nama sesuai tahap entri tim — bukan selalu tahap 0).
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
			var tahap_idx := clampi(int(e.get("tahap", 0)), 0, tahapan.size() - 1)
			nama = String(tahapan[tahap_idx].get("nama", "?"))
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


# ------------------------------------------------------------ antrean battle trainer

## Handoff world scene → battle scene (pola sama dengan antrean encounter liar).
static var antrean_battle: String = ""


static func set_antrean(id: String) -> void:
	antrean_battle = id


## Ambil & kosongkan antrean (dikonsumsi battle scene sekali saat mulai).
static func ambil_antrean() -> String:
	var hasil := antrean_battle
	antrean_battle = ""
	return hasil