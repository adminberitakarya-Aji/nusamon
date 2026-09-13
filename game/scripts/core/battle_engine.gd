class_name BattleEngine
extends RefCounted
## Inti battle turn-based prototipe NUSAMON.
## Rumus damage (GDD §4.1):
##   dasar   = floor(floor(floor(2*level/5 + 2) * power * ATK/DEF) / 50) + 2
##   damage  = floor(dasar * eff * STAB * krit * random(0.85-1.00))

const STAB_BONUS := 1.5
const PELUANG_KRITIS := 0.0625
const BONUS_KRITIS := 1.5
const RAND_MIN := 0.85
const RAND_MAX := 1.0

const PELUANG_LOMPAT_KELUMPUHAN := 0.25

## Move darurat bila semua PP habis (konvensi Pokémon: Struggle).
const SAMARAN := {
	"id": "meronta", "nama": "Meronta", "tipe": "Normal", "kategori": "fisik",
	"power": 50, "akurasi": 100, "prioritas": 0, "efekData": null
}


## Faktor tahap stat (konvensi Pokémon): +1=×1.5, −1=×2/3, batas -6..+6.
static func faktor_tahap(tahap: int) -> float:
	return (2.0 + tahap) / 2.0 if tahap >= 0 else 2.0 / (2.0 - tahap)


## Cari move berdasarkan id di data/moves.json.
static func cari_move(moves_db: Dictionary, id: String) -> Dictionary:
	for mv in moves_db.get("moves", []):
		if String(mv.get("id", "")) == id:
			return mv
	push_error("BattleEngine: move tidak ditemukan: " + id)
	return {}


## Jalankan satu serangan. Deterministik terhadap rng (urutan: akurasi → kritis → random).
## Mengembalikan {damage, eff, stab, kritis, missed}.
static func execute_move(
		penyerang: NusamonInstance, bertahan: NusamonInstance,
		move: Dictionary, chart: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var hasil := {"damage": 0, "eff": 1.0, "stab": false, "kritis": false, "missed": false}

	# 1) akurasi (Mata Elang: selalu kena — roll akurasi dilewati)
	var akurasi := float(move.get("akurasi", 100.0))
	if akurasi > 0.0 and not AbilityEngine.akurasi_selalu(penyerang) \
			and rng.randf() * 100.0 > akurasi:
		hasil["missed"] = true
		return hasil

	# 2) move status: tidak berdaman
	var power := float(move.get("power", 0.0))
	if power <= 0.0:
		return hasil

	# 3) stat serang/bertahan sesuai kategori + tahap stat (buff/debuff)
	var kategori := String(move.get("kategori", "fisik"))
	var atk_key := "atk" if kategori == "fisik" else "spa"
	var def_key := "def" if kategori == "fisik" else "spd"
	var atk := float(penyerang.stats[atk_key]) * faktor_tahap(int(penyerang.stat_stages.get(atk_key, 0))) \
		* AbilityEngine.faktor_setengah(penyerang, kategori)
	var defn := float(bertahan.stats[def_key]) * faktor_tahap(int(bertahan.stat_stages.get(def_key, 0)))
	# luka bakar memotong serangan fisik
	if kategori == "fisik" and penyerang.status == "luka_bakar":
		atk *= 0.5

	# 4) rumus dasar
	var lvl := float(penyerang.level)
	var dasar: float = floor(floor(floor(2.0 * lvl / 5.0 + 2.0) * power * atk / defn) / 50.0) + 2.0

	# 5) efektivitas tipe (dual-type: kalikan semua kolom)
	var tipe_move := String(move.get("tipe", "Normal"))
	var eff := 1.0
	for d in bertahan.types:
		eff *= NusamonData.effectiveness(chart, tipe_move, String(d))
	hasil["eff"] = eff

	# 6) STAB
	var stab: bool = penyerang.types.has(tipe_move)
	hasil["stab"] = stab

	# 7) kritis + faktor random
	var kritis: bool = rng.randf() < PELUANG_KRITIS
	hasil["kritis"] = kritis
	var faktor := rng.randf_range(RAND_MIN, RAND_MAX)

	var modifier: float = eff * (STAB_BONUS if stab else 1.0) \
		* (BONUS_KRITIS if kritis else 1.0) * faktor
	var dmg := 0
	if eff != 0.0:
		dmg = int(floor(dasar * modifier))
		# Kulit Tebal: damage fisik yang diterima −10%
		if kategori == "fisik":
			dmg = int(floor(float(dmg) * AbilityEngine.faktor_kulit_tebal(bertahan)))
	hasil["damage"] = dmg
	return hasil


## Urutan giliran: prioritas move dulu, lalu SPE; seri → penyerang A dulu.
static func urutan_giliran(
		a: NusamonInstance, move_a: Dictionary,
		b: NusamonInstance, move_b: Dictionary) -> Array:
	var pri_a := int(move_a.get("prioritas", 0))
	var pri_b := int(move_b.get("prioritas", 0))
	if pri_a != pri_b:
		return [a, b] if pri_a > pri_b else [b, a]
	var spe_a := float(a.stats["spe"]) * faktor_tahap(int(a.stat_stages.get("spe", 0)))
	var spe_b := float(b.stats["spe"]) * faktor_tahap(int(b.stat_stages.get("spe", 0)))
	if spe_a == spe_b:
		return [a, b]
	return [a, b] if spe_a > spe_b else [b, a]


## Terapkan status baru. Tidur berlangsung 2-4 giliran.
static func terapkan_status(mon: NusamonInstance, jenis: String, rng: RandomNumberGenerator) -> void:
	mon.status = jenis
	if jenis == "tidur":
		mon.status_turn = rng.randi_range(2, 4)


## Efek status di akhir giliran; mengembalikan pesan untuk log battle.
## Catatan: kelumpuhan dicek saat mon mencoba beraksi (battle_scene), bukan di sini.
static func akhir_giliran_status(mon: NusamonInstance, rng: RandomNumberGenerator) -> String:
	match mon.status:
		"luka_bakar":
			var d: int = maxi(1, int(floor(float(mon.max_hp) / 16.0)))
			mon.take_damage(d)
			return "%s terluka karena luka bakar (-%d HP)" % [mon.display_name, d]
		"racun":
			var d: int = maxi(1, int(floor(float(mon.max_hp) / 8.0)))
			mon.take_damage(d)
			return "%s kesakitan karena racun (-%d HP)" % [mon.display_name, d]
		"tidur":
			mon.status_turn -= 1
			if mon.status_turn <= 0:
				mon.status = ""
				return "%s terbangun!" % mon.display_name
			return "%s tidur nyenyak..." % mon.display_name
	return ""
