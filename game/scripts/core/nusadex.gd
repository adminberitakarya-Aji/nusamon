class_name Nusadex
extends RefCounted
## Nusadex (Pokédex versi NUSAMON) — static store sesi, 30 spesies.
## Melihat liar → entri "lihat" (siluet + nama); menangkap → entri lengkap
## (docs/nusadex.md §2). Save/load permanen menyusul di Fase 2.

const TOTAL := 30

static var entri := {}   # id spesies (int) -> {"lihat": bool, "tangkap": bool}


## Kosongkan Nusadex (prototipe/tes).
static func reset() -> void:
	entri = {}


static func _valid_id(id: int) -> bool:
	return id >= 1 and id <= TOTAL


## Catat "terlihat" (idempotent); false bila id tidak valid.
static func lihat(id: int) -> bool:
	if not _valid_id(id):
		return false
	var e: Dictionary = entri.get(id, {})
	e["lihat"] = true
	entri[id] = e
	return true


## Catat "tertangkap" (implisit juga terlihat); false bila id tidak valid.
static func tangkap(id: int) -> bool:
	if not _valid_id(id):
		return false
	lihat(id)
	var e: Dictionary = entri.get(id, {})
	e["tangkap"] = true
	entri[id] = e
	return true


static func sudah_lihat(id: int) -> bool:
	if not _valid_id(id):
		return false
	return bool(entri.get(id, {}).get("lihat", false))


static func sudah_tangkap(id: int) -> bool:
	if not _valid_id(id):
		return false
	return bool(entri.get(id, {}).get("tangkap", false))


static func jumlah_lihat() -> int:
	var n := 0
	for id in entri:
		if sudah_lihat(int(id)):
			n += 1
	return n


static func jumlah_tangkap() -> int:
	var n := 0
	for id in entri:
		if sudah_tangkap(int(id)):
			n += 1
	return n
