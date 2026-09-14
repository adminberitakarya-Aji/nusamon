class_name Inventori
extends RefCounted
## Inventori sesi (static): uang + stok item. Bertahan selama aplikasi berjalan
## (tidak hilang saat battle scene dimuat ulang). Save/load permanen menyusul di Fase 2.
## Data item/harga: data/items.json (single source of truth) via NusamonData.load_items().

const UANG_AWAL := 3000
const STOK_AWAL := {"amukan": 5}

static var uang: int = UANG_AWAL
static var stok: Dictionary = {"amukan": 5}
static var _cache := {}   # cache data/items.json


## Kembalikan ke kondisi awal (prototipe/tes).
static func reset() -> void:
	uang = UANG_AWAL
	stok = {}
	for id in STOK_AWAL:
		stok[String(id)] = int(STOK_AWAL[id])


static func _items_db() -> Dictionary:
	if _cache.is_empty():
		_cache = NusamonData.load_items()
	return _cache


## Semua item dengan jenis tertentu dari data/items.json.
static func items_jenis(jenis: String) -> Array:
	var hasil: Array = []
	for it in _items_db().get("items", []):
		if String(it.get("jenis", "")) == jenis:
			hasil.append(it)
	return hasil


## Semua item jenis "amukan" dari data/items.json.
static func daftar_amukan() -> Array:
	return items_jenis("amukan")


## Harga item; -1 bila tak dikenal/tak dijual (harga null).
static func harga(id: String) -> int:
	for it in _items_db().get("items", []):
		if String(it.get("id", "")) == id:
			var h: Variant = it.get("harga")
			return -1 if h == null else int(h)
	return -1


static func stok_item(id: String) -> int:
	return int(stok.get(id, 0))


static func tambah_item(id: String, n: int) -> void:
	stok[id] = stok_item(id) + n


## Pakai 1 item; false bila stok habis.
static func pakai_item(id: String) -> bool:
	if stok_item(id) <= 0:
		return false
	stok[id] = stok_item(id) - 1
	return true


## Nama tampilan item dari data/items.json; kembalikan id bila tak dikenal.
static func nama_item(id: String) -> String:
	for it in _items_db().get("items", []):
		if String(it.get("id", "")) == id:
			return String(it.get("nama", id))
	return id


## Daftar id item kunci (jenis "kunci") yang sedang dimiliki (stok > 0).
## Dipakai komposisi progres untuk gate dunia (WorldEngine jenis "item").
static func kunci_dimiliki() -> Array:
	var hasil: Array = []
	for it in items_jenis("kunci"):
		var iid := String(it.get("id", ""))
		if stok_item(iid) > 0:
			hasil.append(iid)
	return hasil


## Beli 1 item dari toko; false bila tak dijual / uang kurang.
static func beli(id: String) -> bool:
	var h := harga(id)
	if h < 0:
		return false
	if uang < h:
		return false
	uang -= h
	tambah_item(id, 1)
	return true
