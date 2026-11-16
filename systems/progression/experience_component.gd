class_name ExperienceComponent
extends Node
## Experiencia y nivel de quien la gana (el jugador). Suma lo que recoge de su tipo de recompensa
## ([member reward], por [code]EventBus.pickup_collected[/code]) multiplicado por su stat
## [code]xp_gain[/code], y sube de nivel según la curva de [member data] (puede subir varios de
## golpe). Lo que sobra pasa al nivel siguiente.

## Cambió la experiencia ([param current] de [param needed] para el siguiente) o el nivel.
signal xp_changed(current: float, needed: float, level: int)
signal leveled_up(level: int)

@export var data: ExperienceData
## Stats de quien gana la experiencia (su [code]xp_gain[/code]).
@export var stats: StatsComponent
## Recompensa de los recogibles que cuentan como experiencia.
@export var reward: StringName = &"experience"

var _level: int = 1
var _xp: float = 0.0


func _enter_tree() -> void:
	if not EventBus.pickup_collected.is_connected(_on_pickup_collected):
		EventBus.pickup_collected.connect(_on_pickup_collected)


func _ready() -> void:
	xp_changed.emit(_xp, needed(), _level)


## Suma [param amount] de experiencia (antes de [code]xp_gain[/code]).
func add(amount: float) -> void:
	if _level >= data.max_level:
		return
	_xp += amount * _gain()
	while _level < data.max_level and _xp >= needed():
		_xp -= needed()
		_level += 1
		leveled_up.emit(_level)
	if _level >= data.max_level:
		_xp = 0.0
	xp_changed.emit(_xp, needed(), _level)


func get_level() -> int:
	return _level


## Experiencia acumulada hacia el siguiente nivel.
func get_xp() -> float:
	return _xp


## Experiencia necesaria para pasar al siguiente nivel.
func needed() -> float:
	return data.needed_for(_level)


func _gain() -> float:
	return stats.get_value(&"xp_gain") / 100.0 if stats else 1.0


func _on_pickup_collected(kind: StringName, amount: float) -> void:
	if kind == reward:
		add(amount)
