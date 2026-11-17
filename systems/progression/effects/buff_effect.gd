class_name BuffEffect
extends PickupEffect
## Mejora temporal (la bebida energética): aplica [member buff] a las stats del jugador durante los
## segundos que vale el recogible. Coger otro mientras dura no lo acumula: vuelve a empezar la
## cuenta. Con el juego en pausa, el tiempo no corre.

## Stats que mejora (las del jugador).
@export var stats: StatsComponent
## Modificadores que aplica mientras dura.
@export var buff: StatModifierSet

var _left: float = 0.0


func _ready() -> void:
	set_process(false)


func apply(amount: float) -> void:
	if not is_active():
		for modifier: StatModifier in buff.stat_modifiers:
			stats.add_modifier(modifier, self)
	_left = maxf(_left, amount)
	set_process(true)


## ¿Está haciendo efecto?
func is_active() -> bool:
	return _left > 0.0


## Segundos que le quedan.
func get_time_left() -> float:
	return _left


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		_left = 0.0
		stats.remove_modifiers_from(self)
		set_process(false)


func _exit_tree() -> void:
	if is_active() and is_instance_valid(stats):
		stats.remove_modifiers_from(self)
