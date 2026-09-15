class_name Tim
extends RefCounted
## Tim/partai pemain (static store) — maksimal 6 anggota, persisten selama sesi.
## Mon aktif dipakai battle; hasil tangkap masuk tim (Fase 2). Referensi instance
## yang sama dipakai antar battle → EXP/level/evolusi tidak hilang saat scene dimuat ulang.
## Save/load permanen menyusul di Fase 2.

const MAKS := 6

static var anggota: Array = []      # NusamonInstance
static var aktif_index := 0


## Kosongkan tim (prototipe/tes).
static func reset() -> void:
	anggota = []
	aktif_index = 0


static func jumlah() -> int:
	return anggota.size()


static func penuh() -> bool:
	return anggota.size() >= MAKS


## Tambah anggota; false bila penuh/null/sudah ada di tim.
static func tambah(inst: NusamonInstance) -> bool:
	if inst == null or penuh() or anggota.has(inst):
		return false
	anggota.append(inst)
	return true


## Mon aktif (null bila tim kosong).
static func aktif() -> NusamonInstance:
	if anggota.is_empty():
		return null
	return anggota[clampi(aktif_index, 0, anggota.size() - 1)]


## Lepaskan (release) anggota tim dari koleksi — Fase 5 (Nusadex tetap tercatat).
## Anggota terakhir tidak boleh dilepas (tim tak boleh kosong).
## Mengembalikan instance yang dilepas; null bila index tidak valid / anggota tunggal.
static func lepas(index: int) -> NusamonInstance:
	if index < 0 or index >= anggota.size():
		return null
	if anggota.size() <= 1:
		return null
	var dilepas: NusamonInstance = anggota[index]
	anggota.remove_at(index)
	if aktif_index >= anggota.size():
		aktif_index = anggota.size() - 1
	return dilepas


## Ganti mon aktif; false bila index tidak valid.
static func ubah_aktif(idx: int) -> bool:
	if idx < 0 or idx >= anggota.size():
		return false
	aktif_index = idx
	return true


## Cari anggota berdasarkan spesies id; kembalikan index atau -1.
static func cari_spesies(id: int) -> int:
	for i in anggota.size():
		if anggota[i].id == id:
			return i
	return -1


## Pulihkan seluruh tim (HP penuh + bersihkan status) — analog pusat pemulihan.
## Mengembalikan jumlah anggota yang benar-benar dipulihkan.
static func pulihkan_semua() -> int:
	var n := 0
	for m in anggota:
		if m.current_hp < m.max_hp or m.status != "":
			m.heal(m.max_hp)
			m.status = ""
			m.status_turn = 0
			n += 1
	return n
