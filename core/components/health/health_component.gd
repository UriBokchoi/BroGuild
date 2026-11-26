class_name HealthComponent
extends Node
## Vida de una entidad (jugador o enemigo). Lee sus stats de supervivencia ([HealthData]) de su
## [StatsComponent]: vida máxima, regeneración, defensa y esquiva. Recibe golpes ([DamageInfo]), los
## esquiva o los reduce con la defensa ([DamageCalc]) y avisa con señales. Al llegar a 0 muere, una
## sola vez.

## Cambió la vida actual o la máxima.
signal health_changed(current: float, maximum: float)
## Recibió un golpe de [param amount] de daño, ya reducido por la defensa. Es lo que valía el golpe
## (lo que muestran los números de daño): puede pasar de la vida que quedaba.
signal damaged(amount: float, info: DamageInfo)
## Esquivó el golpe entero.
signal evaded(info: DamageInfo)
signal died
## Recibió daño: durante [param seconds] no recibirá más
## ([member HealthData.invulnerability_time]).
signal invulnerability_started(seconds: float)

@export var stats: StatsComponent
@export var rules: CombatRules
## Recibe los golpes y avisa de ellos, pero la vida no baja ni muere (el muñeco de práctica).
@export var immortal: bool = false

## Azar de la esquiva. Si no se asigna antes de entrar en el árbol, el flujo de combate de [code]Rng[/code].
var rng: RandomNumberGenerator
## Vida de la que no baja mientras le quede (la rabia del Bárbaro: no puede morir). 0: ninguna.
var floor_health: float = 0.0
## Quien decide si un golpe que lo iba a matar no lo mata (devuelve [code]true[/code]): se queda con
## [member floor_health] o con 1 de vida (la pasiva Furia). Vacío: muere.
var death_guard: Callable

var _data: HealthData
var _current: float = 0.0
var _dead: bool = false
## Hasta cuándo no recibe daño, en segundos de [PhysicsClock].
var _invulnerable_until: float = -1.0


func _ready() -> void:
	_data = stats.get_resolved(HealthData) as HealthData
	if rng == null:
		rng = Rng.stream(Rng.Stream.COMBAT)
	_current = _data.max_health
	stats.stat_changed.connect(_on_stat_changed)
	# Solo procesa si regenera: hay cientos de enemigos sin regeneración.
	set_physics_process(_data.health_regen > 0.0)
	health_changed.emit(_current, _data.max_health)


func _physics_process(delta: float) -> void:
	if _current < _data.max_health:
		heal(_data.health_regen * delta)


func get_current() -> float:
	return _current


func get_maximum() -> float:
	return _data.max_health


func is_dead() -> bool:
	return _dead


## ¿Está en sus segundos sin recibir daño tras un golpe?
func is_invulnerable() -> bool:
	return PhysicsClock.now() < _invulnerable_until


## Recibe un golpe. Devuelve la vida que quitó de verdad (0 si lo esquiva, si ya estaba muerto, si
## es inmortal o si está en sus segundos de invulnerabilidad tras otro golpe).
func take_damage(info: DamageInfo) -> float:
	if _dead or is_invulnerable():
		return 0.0
	if DamageCalc.evades(_data.evasion, rng):
		evaded.emit(info)
		return 0.0
	var amount := DamageCalc.after_armor(info.amount, _data.armor, rules)
	var removed := 0.0 if immortal else minf(amount, _current)
	if not immortal and removed >= _current - floor_health and _spares_death(removed):
		removed = maxf(_current - maxf(floor_health, 1.0), 0.0)
	_current -= removed
	damaged.emit(amount, info)
	if removed > 0.0:
		health_changed.emit(_current, _data.max_health)
	if _current <= 0.0:
		_dead = true
		died.emit()
	elif amount > 0.0 and _data.invulnerability_time > 0.0:
		_invulnerable_until = PhysicsClock.now() + _data.invulnerability_time
		invulnerability_started.emit(_data.invulnerability_time)
	return removed


## ¿Un golpe que quita [param removed] no lo deja por debajo de su suelo? Con suelo, nunca baja de él;
## sin él, si el golpe lo mataría, decide [member death_guard].
func _spares_death(removed: float) -> bool:
	if floor_health > 0.0:
		return true
	return removed >= _current and death_guard.is_valid() and death_guard.call()


## Cura [param amount] sin pasar de la vida máxima. Muerto no cura.
func heal(amount: float) -> void:
	if _dead:
		return
	var healed := minf(_current + amount, _data.max_health)
	if healed != _current:
		_current = healed
		health_changed.emit(_current, _data.max_health)


## Vuelve a la vida máxima, vivo (un enemigo que sale otra vez del pool).
func reset() -> void:
	_dead = false
	_invulnerable_until = -1.0
	_current = _data.max_health
	health_changed.emit(_current, _data.max_health)


func _on_stat_changed(stat: StringName, value: float, previous: float) -> void:
	if stat == &"health_regen":
		set_physics_process(value > 0.0)
	if stat != &"max_health":
		return
	# Subir la vida máxima cura la diferencia; bajarla solo recorta la actual.
	if value > previous and not _dead:
		_current += value - previous
	_current = minf(_current, value)
	health_changed.emit(_current, value)
