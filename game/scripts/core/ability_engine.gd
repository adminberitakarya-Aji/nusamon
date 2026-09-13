class_name AbilityEngine
extends RefCounted
## Engine 12 ability pasif (docs/gameplay-depth.md §1). Semua fungsi static;
## deterministik terhadap rng bila melibatkan peluang.
## Pemetaan ability → spesies: docs/gameplay-depth.md & data/nusamons.json (detailSpesies.ability).

const BONUS_SETENGAH_HP := 1.5     # taring_tajam / napas_dalam
const PEMULIHAN_PANEN := 0.125     # panen_subur (12.5% HP per giliran)
const REDUKSI_KULIT_TEBAL := 0.9   # kulit_tebal (damage fisik diterima −10%)
const PELUANG_HINDAR := 0.10       # refleks_kilat
const PELUANG_SENTUH := 0.30       # racun_alami / serbuk_sari / madu_manis
const PELUANG_TERPIKAT_GAGAL := 0.50  # efek status "terpikat" (madu_manis)


## HP mon ≤ 1/3 (syarat taring_tajam / napas_dalam / panen_subur).
static func hp_seperatiga(mon: NusamonInstance) -> bool:
	return mon.current_hp > 0 and mon.current_hp * 3 <= mon.max_hp


## Faktor ATK/SPA saat HP ≤ 1/3: taring_tajam (fisik) & napas_dalam (spesial) ×1.5.
static func faktor_setengah(mon: NusamonInstance, kategori: String) -> float:
	var cocok := (mon.ability == "taring_tajam" and kategori == "fisik") \
		or (mon.ability == "napas_dalam" and kategori == "spesial")
	if cocok and hp_seperatiga(mon):
		return BONUS_SETENGAH_HP
	return 1.0


## Mata Elang: akurasi move pengguna selalu 100%.
static func akurasi_selalu(mon: NusamonInstance) -> bool:
	return mon.ability == "mata_elang"


## Kulit Tebal: damage serangan fisik yang diterima −10%.
static func faktor_kulit_tebal(mon: NusamonInstance) -> float:
	return REDUKSI_KULIT_TEBAL if mon.ability == "kulit_tebal" else 1.0


## Refleks Kilat: 10% peluang menghindari serangan (dipanggil oleh bertahan).
static func refleks_hindar(mon: NusamonInstance, rng: RandomNumberGenerator) -> bool:
	return mon.ability == "refleks_kilat" and rng.randf() < PELUANG_HINDAR


## Cengkeraman Kuat: lawan tidak dapat bertukar/kabur selama pengguna aktif.
static func lawan_terkunci(ability_pengguna: String) -> bool:
	return ability_pengguna == "cengkeraman_kuat"


## Efek saat mon masuk battle (Pengguna = mon masuk; lawan = mon seberang).
## Mengembalikan pesan log ("" bila tidak ada).
static func masuk_battle(pengguna: NusamonInstance, lawan: NusamonInstance) -> String:
	var pesan := ""
	if pengguna.ability == "pelindung_karang":
		pengguna.ubah_tahap_stat("def", 1)
		pesan += "DEF %s naik (Pelindung Karang)!" % pengguna.display_name
	if lawan != null and pengguna.ability == "tiruan_suara":
		lawan.ubah_tahap_stat("atk", -1)
		if pesan != "":
			pesan += "\n"
		pesan += "ATK %s turun (Tiruan Suara %s)!" % [
			lawan.display_name, pengguna.display_name]
	return pesan


## Ability penyentuh fisik: bertahan merespons penyerang (fisik saja).
## Mengembalikan pesan log ("" bila tidak ada).
static func sentuh_fisik(
		penyerang: NusamonInstance, bertahan: NusamonInstance,
		rng: RandomNumberGenerator) -> String:
	if penyerang.status != "":
		return ""
	match bertahan.ability:
		"racun_alami":
			if rng.randf() < PELUANG_SENTUH:
				penyerang.status = "racun"
				return "%s teracuni Racun Alami %s!" % [
					penyerang.display_name, bertahan.display_name]
		"serbuk_sari":
			if rng.randf() < PELUANG_SENTUH:
				penyerang.status = "tidur"
				penyerang.status_turn = rng.randi_range(2, 4)
				return "%s mengantuk oleh Serbuk Sari %s!" % [
					penyerang.display_name, bertahan.display_name]
		"madu_manis":
			if rng.randf() < PELUANG_SENTUH:
				penyerang.status = "terpikat"
				return "%s terpikat oleh Madu Manis %s!" % [
					penyerang.display_name, bertahan.display_name]
	return ""


## Efek ability di akhir giliran: Panen Subur (pulih 12.5% saat HP ≤ 1/3).
static func akhir_giliran(mon: NusamonInstance) -> String:
	if mon.ability == "panen_subur" and hp_seperatiga(mon):
		var pulih := maxi(1, int(floor(float(mon.max_hp) * PEMULIHAN_PANEN)))
		mon.heal(pulih)
		return "%s memulihkan %d HP (Panen Subur)!" % [mon.display_name, pulih]
	return ""