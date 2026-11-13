class_name DpsMeter
extends Label3D
## Daño por segundo y daño total que recibe una vida (el muñeco de práctica). Mide desde el primer
## golpe; tras [member reset_after] segundos sin golpes deja el último resultado y el siguiente
## golpe empieza una medición nueva.

@export var health: HealthComponent
## Segundos sin golpes que cierran la medición.
@export_range(0.5, 30.0, 0.1, "suffix:s") var reset_after: float = 3.0
## Tiempo mínimo por el que dividir, para que los primeros golpes no den un DPS disparado.
@export_range(0.1, 10.0, 0.1, "suffix:s") var min_window: float = 1.0

var _clock: float = 0.0
var _started_at: float = 0.0
var _last_hit_at: float = 0.0
var _total: float = 0.0
var _hits: int = 0
var _measuring: bool = false
var _dps: float = 0.0


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	_show()


func _physics_process(delta: float) -> void:
	_clock += delta
	if not _measuring:
		return
	if _clock - _last_hit_at >= reset_after:
		_measuring = false
		_dps = _total / maxf(_closed_window(), min_window)
	else:
		_dps = _total / maxf(_clock - _started_at, min_window)
	_show()


## Daño por segundo de la medición actual (o de la última, si ya se cerró).
func get_dps() -> float:
	return _dps


## Daño total de la medición actual (o de la última).
func get_total() -> float:
	return _total


func _on_damaged(amount: float, _info: DamageInfo) -> void:
	if not _measuring:
		_measuring = true
		_started_at = _clock
		_total = 0.0
		_hits = 0
	_total += amount
	_hits += 1
	_last_hit_at = _clock


## Duración de una medición cerrada: hasta el último golpe más el intervalo medio entre golpes (sin
## el rato que estuvo esperando a que se cerrara).
func _closed_window() -> float:
	var span := _last_hit_at - _started_at
	return span * _hits / (_hits - 1) if _hits > 1 else 0.0


func _show() -> void:
	var shown := "%s\n%s" % [
		tr(&"DUMMY_DPS") % roundi(_dps),
		tr(&"DUMMY_TOTAL") % roundi(_total),
	]
	if shown != text:
		text = shown
