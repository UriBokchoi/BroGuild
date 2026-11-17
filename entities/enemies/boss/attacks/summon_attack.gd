class_name SummonAttack
extends BossAttack
## Refuerzos (los «Bro-tes» del Ent-renador): se para y crece un poco mientras los llama; luego salen
## [member count] enemigos de [member enemy] a su alrededor ([member enraged_count] con rabia). Los
## pone en juego quien sacó al jefe ([signal Boss.summon_requested]).

## Qué enemigo llama.
@export var enemy: EnemyData
## Cuántos.
@export_range(1, 50, 1) var count: int = 4
## Cuántos con rabia.
@export_range(1, 50, 1) var enraged_count: int = 6
## Distancia mínima y máxima al jefe a la que salen.
@export_range(0.5, 50.0, 0.5, "suffix:m") var min_distance: float = 3.0
@export_range(0.5, 50.0, 0.5, "suffix:m") var max_distance: float = 7.0
## Segundos llamándolos.
@export_range(0.0, 5.0, 0.05, "suffix:s") var windup: float = 1.0
## Segundos quieto después.
@export_range(0.0, 5.0, 0.05, "suffix:s") var recovery: float = 0.4
## Alto del modelo mientras los llama (1 = normal).
@export_range(1.0, 2.0, 0.05) var stretch: float = 1.15

var _left: float = 0.0
var _called: bool = false


func begin(_target: Vector3) -> void:
	_left = windup
	_called = false


func step(delta: float, target: Vector3) -> bool:
	_left -= delta
	boss.move_flat(Vector3.ZERO)
	boss.face_toward(target, delta)
	if _called:
		return _left <= 0.0
	boss.squash(lerpf(stretch, 1.0, maxf(_left, 0.0) / maxf(windup, 0.001)))
	if _left <= 0.0:
		boss.squash(1.0)
		boss.summon(enemy, enraged_count if boss.is_enraged() else count, min_distance, max_distance)
		_called = true
		_left = recovery
	return false


func cancel() -> void:
	boss.squash(1.0)
