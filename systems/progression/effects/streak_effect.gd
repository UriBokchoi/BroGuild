class_name StreakEffect
extends PickupEffect
## La racha (un power-up): durante los segundos que vale, derrotar enemigos sube su nivel, que
## multiplica el oro y la experiencia y suma Suerte. Si golpean al jugador, baja un nivel. Coger otra
## mientras dura alarga el tiempo sin perder el nivel. Con el juego en pausa, el tiempo no corre.

## Niveles, multiplicadores y Suerte.
@export var data: StreakData
## Las stats del jugador (las del oro, la experiencia y la Suerte).
@export var stats: StatsComponent
## La vida del jugador: un golpe baja un nivel.
@export var health: HealthComponent

var _left: float = 0.0
var _kills: int = 0
var _level: int = 0


func _ready() -> void:
	set_process(false)
	EventBus.enemy_died.connect(_on_enemy_died)
	if health:
		health.damaged.connect(_on_damaged)


func apply(amount: float) -> void:
	if not is_active():
		_kills = 0
		_level = 0
		_apply_level()
	_left = maxf(_left, amount)
	set_process(true)
	_announce()


## ¿Está en marcha?
func is_active() -> bool:
	return _left > 0.0


## El multiplicador de ahora (1 sin racha).
func get_multiplier() -> float:
	return data.multipliers[_level] if is_active() else 1.0


## Segundos que le quedan.
func get_time_left() -> float:
	return _left


func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		_announce()
		return
	_left = 0.0
	_level = 0
	stats.remove_modifiers_from(self)
	set_process(false)
	EventBus.streak_changed.emit(0.0, 0.0)


func _exit_tree() -> void:
	if is_active() and is_instance_valid(stats):
		stats.remove_modifiers_from(self)


func _on_enemy_died(_enemy: Enemy) -> void:
	if not is_active():
		return
	_kills += 1
	var level := data.level_for(_kills)
	if level != _level:
		_level = level
		_apply_level()
		_announce()


func _on_damaged(amount: float, _info: DamageInfo) -> void:
	if not is_active() or _level == 0 or amount <= 0.0:
		return
	_level -= 1
	_kills = data.kills[_level]
	_apply_level()
	_announce()


## Cambia los modificadores por los del nivel de ahora.
func _apply_level() -> void:
	stats.remove_modifiers_from(self)
	var multiplier := data.multipliers[_level]
	if multiplier <= 1.0:
		return
	stats.add_modifier(StatModifier.create(&"currency_gain", StatModifier.Kind.MULTIPLIER, multiplier), self)
	stats.add_modifier(StatModifier.create(&"xp_gain", StatModifier.Kind.MULTIPLIER, multiplier), self)
	var luck := (multiplier - 1.0) * data.luck_per_multiplier
	stats.add_modifier(StatModifier.create(&"luck", StatModifier.Kind.FLAT, luck), self)


func _announce() -> void:
	EventBus.streak_changed.emit(get_multiplier(), _left)
