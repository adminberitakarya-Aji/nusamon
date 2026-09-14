class_name Simpanan
extends RefCounted
## Save/load sesi pemain ke user://simpanan.json (JSON v2).
## Konten: versi, uang, stok inventori, tim (id spesies, tahap, level, HP,
## status, exp_total, latihan), nusadex (lihat/tangkap), aktif_index —
## v2 + progres dunia (lokasi, lencana, trainer_kalah) — Fase 3 langkah 5.
## Migrasi: save v1 masih dimuat (progres = default kosong).
## Penulisan via FileAccess + JSON.stringify; pembacaan tervalidasi (versi).

const PATH := "user://simpanan.json"
const VERSI := 2


## Kembalikan dict state penuh (dipakai simpan & tes).
static func ambil_state() -> Dictionary:
	var tim: Array = []
	for m in Tim.anggota:
		tim.append({
			"id": m.id, "tahap": m.stage_index, "level": m.level,
			"hp": m.current_hp, "status": m.status,
			"exp_total": m.exp_total,
			"latihan": m.latihan_untuk_save(),
		})
	var dex: Array = []
	for id in Nusadex.entri:
		dex.append({"id": int(id), "lihat": Nusadex.sudah_lihat(int(id)),
			"tangkap": Nusadex.sudah_tangkap(int(id))})
	return {"versi": VERSI, "uang": Inventori.uang, "stok": Inventori.stok.duplicate(),
		"tim": tim, "aktif_index": Tim.aktif_index, "nusadex": dex,
		"progres": {
			"lokasi": Progres.lokasi,
			"lencana": Progres.lencana.duplicate(),
			"trainer_kalah": Progres.trainer_kalah.duplicate(),
			"starter": Progres.starter_id,
		}}


static func simpan() -> bool:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("Simpanan: gagal menulis " + PATH)
		return false
	f.store_string(JSON.stringify(ambil_state(), "\t"))
	f.close()
	return true


## Muat state; mengembalikan true bila berhasil (state sesi diganti).
static func muat() -> bool:
	if not FileAccess.file_exists(PATH):
		return false
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return false
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Simpanan: JSON tidak valid")
		return false
	var versi := int(data.get("versi", 0))
	if versi < 1 or versi > VERSI:
		push_error("Simpanan: versi tidak didukung (%d)" % versi)
		return false
	terapkan(data)
	return true


## Terapkan dict state ke sesi berjalan (dipisah agar testable).
## Terapkan dict state ke sesi berjalan (dipisah agar testable).
static func terapkan(data: Dictionary) -> void:
	Inventori.uang = int(data.get("uang", Inventori.UANG_AWAL))
	var stok_baru := {}
	for k in data.get("stok", {}):
		stok_baru[String(k)] = int(data["stok"][k])
	Inventori.stok = stok_baru
	var db := NusamonData.load_nusamons()
	var detail: Dictionary = db.get("detailSpesies", {})
	Tim.reset()
	for m in data.get("tim", []):
		var id := int(m.get("id", 0))
		if id <= 0 or not detail.has(str(id)):
			continue
		var sp := NusamonData.find_species(db, id)
		var inst := NusamonInstance.create(sp, detail[str(id)], 0, int(m.get("level", 5)))
		inst.stage_index = int(m.get("tahap", 0))
		inst.current_hp = clampi(int(m.get("hp", inst.max_hp)), 0, inst.max_hp)
		inst.status = String(m.get("status", ""))
		inst.exp_total = int(m.get("exp_total", inst.exp_total))
		var lat: Variant = m.get("latihan", {})
		if typeof(lat) == TYPE_DICTIONARY:
			for k in lat:
				var poin := int(lat[k])
				if poin > 0:
					inst.latihan[String(k)] = poin
		inst.latihan_total = 0
		for k in inst.latihan:
			inst.latihan_total += int(inst.latihan[k])
		inst._hitung_stat_efektif()
		Tim.tambah(inst)
	Tim.aktif_index = clampi(int(data.get("aktif_index", 0)), 0, maxi(0, Tim.jumlah() - 1))
	Nusadex.reset()
	for e in data.get("nusadex", []):
		var id2 := int(e.get("id", 0))
		if bool(e.get("tangkap", false)):
			Nusadex.tangkap(id2)
		elif bool(e.get("lihat", false)):
			Nusadex.lihat(id2)
	# progres dunia (v2; save v1 tanpa progres → default kosong — migrasi)
	var prog: Variant = data.get("progres", {})
	if typeof(prog) == TYPE_DICTIONARY:
		var p := prog as Dictionary
		Progres.lokasi = String(p.get("lokasi", ""))
		Progres.lencana = []
		for l in p.get("lencana", []):
			Progres.tambah_lencana(int(l))
		Progres.trainer_kalah = []
		for t in p.get("trainer_kalah", []):
			Progres.tandai_kalah_trainer(String(t))
		Progres.starter_id = maxi(0, int(p.get("starter", 0)))


## Hapus save file (prototipe/tes); true bila tak ada file / berhasil dihapus.
static func hapus() -> bool:
	if FileAccess.file_exists(PATH):
		return DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH)) == OK
	return true