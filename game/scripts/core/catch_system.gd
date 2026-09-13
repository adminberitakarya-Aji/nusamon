class_name CatchSystem
extends RefCounted
## Sistem tangkap (GDD §4.3) — formula basis Gen-V:
##   a = ((3*MaxHP - 2*CurHP) * CatchRate * BallBonus * StatusBonus) / (3*MaxHP)
##   a >= 255 → tangkap pasti. Selain itu 4 shake check.

const BALL_BONUS := {
	"amukan": 1.0,
	"amukan_kuat": 1.5,
	"amukan_super": 2.0,
	"amukan_nusantara": 3.0,
}

const STATUS_BONUS := {
	"tidur": 2.0,
	"racun": 2.0,
	"kelumpuhan": 1.5,
}

const MAX_SHAKES := 4


## Bonus item Amukan (default ×1.0 jika id tidak dikenal).
static func ball_bonus(ball_id: String) -> float:
	return float(BALL_BONUS.get(ball_id, 1.0))


## Peluang tangkap dasar a (0–255+). Semakin tinggi semakin mudah.
static func catch_a(target: NusamonInstance, catch_rate: int, ball_id: String) -> float:
	var max_hp := float(target.max_hp)
	var cur_hp := float(target.current_hp)
	var bonus: float = ball_bonus(ball_id) * float(STATUS_BONUS.get(target.status, 1.0))
	if max_hp <= 0.0:
		return 255.0
	var a := (3.0 * max_hp - 2.0 * cur_hp) * float(catch_rate) * bonus / (3.0 * max_hp)
	return a


## Satu lemparan Amukan. Deterministik terhadap rng.
## Mengembalikan {catch: bool, shakes: int (0–4), guaranteed: bool}.
static func attempt_catch(
		target: NusamonInstance, catch_rate: int, ball_id: String,
		rng: RandomNumberGenerator) -> Dictionary:
	var a := catch_a(target, catch_rate, ball_id)
	if a >= 255.0:
		return {"catch": true, "shakes": MAX_SHAKES, "guaranteed": true}

	# shake threshold (konvensi formula Pokémon)
	var b: float = 1048560.0 / floor(sqrt(floor(sqrt(floor(16711680.0 / a)))))
	var shakes := 0
	for i in MAX_SHAKES:
		if rng.randi_range(0, 65535) < b:
			shakes += 1
		else:
			break
	return {"catch": shakes == MAX_SHAKES, "shakes": shakes, "guaranteed": false}
