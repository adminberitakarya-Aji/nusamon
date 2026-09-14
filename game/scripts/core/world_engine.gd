class_name WorldEngine
extends RefCounted
## Engine peta dunia NUSAMON (static) — traversal lokasi + gate data-driven.
## Data: data/world.json (single source of truth) via NusamonData.load_world().
## Terpisah dari UI (konvensi BattleEngine) → testable headless.
## Gate: syarat pada koneksi, mis. {"jenis": "lencana", "id": 1}, diperiksa
## terhadap progres pemain (Progres, atau dict {"lencana": [...]} untuk tes).


## Ambil data lokasi; {} bila id tidak dikenal.
static func lokasi(db: Dictionary, id: String) -> Dictionary:
	for l in db.get("lokasi", []):
		if String(l.get("id", "")) == id:
			return l
	return {}


## Cek satu syarat gate terhadap progres pemain. Syarat kosong = bebas.
## progres: {"lencana": [id...], "item": [id item yang dimiliki...]}.
static func syarat_terpenuhi(syarat: Dictionary, progres: Dictionary) -> bool:
	if syarat.is_empty():
		return true
	match String(syarat.get("jenis", "")):
		"lencana":
			var daftar: Array = progres.get("lencana", [])
			return daftar.has(int(syarat.get("id", 0)))
		"item":
			var barang: Array = progres.get("item", [])
			return barang.has(String(syarat.get("id", "")))
		_:
			return false   # jenis gate tak dikenal → gagal aman (terkunci)


## Alasan sebuah jalur tidak bisa dilewati; "" bila bebas.
static func alasan_terkunci(db: Dictionary, dari: String, ke: String, progres: Dictionary) -> String:
	var sumber := lokasi(db, dari)
	if sumber.is_empty():
		return "Lokasi asal tidak dikenal."
	var tujuan := lokasi(db, ke)
	if tujuan.is_empty():
		return "Lokasi tujuan tidak dikenal."
	for k in db.get("koneksi", []):
		if String(k.get("dari", "")) == dari and String(k.get("ke", "")) == ke:
			var syarat: Variant = k.get("gate")
			if syarat == null or syarat_terpenuhi(syarat, progres):
				return ""
			var nama_t := String(tujuan.get("nama", ke))
			if String(syarat.get("jenis", "")) == "lencana":
				return "Jalan menuju %s terkunci — butuh Lencana G%d." % [nama_t, int(syarat.get("id", 0))]
			if String(syarat.get("jenis", "")) == "item":
				return "Jalan menuju %s terkunci — butuh %s." % [
					nama_t, String(syarat.get("nama", "item khusus"))]
			return "Jalan menuju %s terkunci." % nama_t
	return "%s dan %s tidak terhubung." % [String(sumber.get("nama", dari)), String(tujuan.get("nama", ke))]


## Daftar tujuan dari satu lokasi (untuk UI): {id, nama, jenis, terkunci, alasan}.
static func daftar_tujuan(db: Dictionary, id: String, progres: Dictionary) -> Array:
	var hasil: Array = []
	for k in db.get("koneksi", []):
		if String(k.get("dari", "")) != id:
			continue
		var t := lokasi(db, String(k.get("ke", "")))
		if t.is_empty():
			continue
		var alasan := alasan_terkunci(db, id, String(t.get("id", "")), progres)
		hasil.append({
			"id": t.get("id", ""),
			"nama": t.get("nama", "?"),
			"jenis": t.get("jenis", "?"),
			"terkunci": alasan != "",
			"alasan": alasan,
		})
	return hasil


## Coba pindah antar lokasi. Hasil: {ok: bool, alasan: String, lokasi: Dictionary}.
## Tidak mengubah state — pemanggil (scene) yang memutakhirkan Progres.lokasi.
static func pindah(db: Dictionary, dari: String, ke: String, progres: Dictionary) -> Dictionary:
	var alasan := alasan_terkunci(db, dari, ke, progres)
	if alasan != "":
		return {"ok": false, "alasan": alasan, "lokasi": {}}
	return {"ok": true, "alasan": "", "lokasi": lokasi(db, ke)}