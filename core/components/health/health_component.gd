class_name HealthComponent
extends Node
## Vida de una entidad (jugador o enemigo). Lee sus stats de supervivencia ([HealthData]) de su
## [StatsComponent]: vida máxima, regeneración, defensa y esquiva. Recibe golpes ([DamageInfo]), los
## esquiva o los reduce con la defensa ([DamageCalc]) y avisa con señales. Al llegar a 0 muere, una
## sola vez.

## Cambió la vida actual o la máxima.
signal health_changed(current: float, maximum: float)
## Recibió [param amount] de daño, ya reducido por la defensa.
signal damaged(amount: float, info: DamageInfo)
## Esquivó el golpe entero.
signal evaded(info: DamageInfo)
signal died

@export var stats: StatsComponent
@export var rules: CombatRules

## Azar de la esquiva. Si no se asigna antes de entrar en el árbol, el flujo de combate de [code]Rng[/code].
var rng: RandomNumberGenerator

var _data: HealthData
var _current: float = 0.0
var _dead: bool = false


func _ready() -> void:
	_data = stats.get_resolved(HealthData) as HealthData
	if rng == null:
		rng = Rng.stream(Rng.Stream.COMBAT)
	_current = _data.max_health
	stats.stat_changed.connect(_on_stat_changed)
	health_changed.emit(_current, _data.max_health)


func _physics_process(delta: float) -> void:
	if _data.health_regen > 0.0 and _current < _data.max_health:
		heal(_data.health_regen * delta)


func get_current() -> float:
	return _current


func get_maximum() -> float:
	return _data.max_health


func is_dead() -> bool:
	return _dead


## Recibe un golpe. Devuelve el daño que hizo de verdad (0 si lo esquiva o ya estaba muerto).
func take_damage(info: DamageInfo) -> float:
	if _dead:
		return 0.0
	if DamageCalc.evades(_data.evasion, rng):
		evaded.emit(info)
		return 0.0
	var amount := minf(DamageCalc.after_armor(info.amount, _data.armor, rules), _current)
	_current -= amount
	damaged.emit(amount, info)
	health_changed.emit(_current, _data.max_health)
	if _current <= 0.0:
		_dead = true
		died.emit()
	return amount


## Cura [param amount] sin pasar de la vida máxima. Muerto no cura.
func heal(amount: float) -> void:
	if _dead:
		return
	var healed := minf(_current + amount, _data.max_health)
	if healed != _current:
		_current = healed
		health_changed.emit(_current, _data.max_health)


func _on_stat_changed(stat: StringName, value: float, previous: float) -> void:
	if stat != &"max_health":
		return
	# Subir la vida máxima cura la diferencia; bajarla solo recorta la actual.
	if value > previous and not _dead:
		_current += value - previous
	_current = minf(_current, value)
	health_changed.emit(_current, value)
