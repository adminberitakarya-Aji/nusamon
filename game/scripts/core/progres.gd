class_name Progres
extends RefCounted
## Progres dunia sesi (static store): lokasi pemain + lencana gym.
## Konvensi Inventori/Nusadex — bertahan saat scene dimuat ulang (dunia ↔ battle).
## Save/load permanen menyusul saat langkah lencana (Fase 3 #5) memperluas
## simpanan.json ke versi 2 (JSON v1 saat ini: uang/stok/tim/nusadex).

static var lokasi: String = ""   # id lokasi pemain; "" = belum mulai jelajah
static var lencana: Array = []   # id lencana gym (int), urut perolehan


## Kembalikan ke kondisi awal (prototipe/tes).
static func reset() -> void:
	lokasi = ""
	lencana = []


static func punya_lencana(id: int) -> bool:
	return lencana.has(id)


## Tambah lencana (idempoten — tak menumpuk duplikat).
static func tambah_lencana(id: int) -> void:
	if not punya_lencana(id):
		lencana.append(id)


static func jumlah_lencana() -> int:
	return lencana.size()