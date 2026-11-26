class_name FuryPassive
extends CharacterPassive
## Furia (el Bárbaro): la primera vez en la partida que un golpe lo iba a matar, se queda a 1 de vida
## y durante [member duration] s no puede morir; se pone rojo de rabia y las stats de
## [member boosted_stats] se multiplican por [member boost]. Al acabar, vuelve a ser mortal.

## Segundos de rabia (sin poder morir).
@export_range(0.5, 60.0, 0.5, "suffix:s") var duration: float = 10.0
## Cuánto suben sus stats con la rabia (1,3 = un 30 % más).
@export_range(1.0, 5.0, 0.05) var boost: float = 1.3
## Stats que suben con la rabia.
@export var boosted_stats: Array[StringName] = []
## Color del brillo de la rabia y su intensidad.
@export var glow_color: Color = Color(1.0, 0.15, 0.1)
@export_range(0.0, 8.0, 0.1) var glow_energy: float = 1.6
## Texto que sale al enfurecerse (clave de traducción).
@export var announce_key: StringName = &""

var _used: bool = false
var _left: float = 0.0


func _activated() -> void:
	player.health.death_guard = _on_lethal_hit
	set_process(false)


func _exit_tree() -> void:
	if player and is_instance_valid(player.health):
		player.health.floor_health = 0.0
		player.health.death_guard = Callable()
	if player and is_instance_valid(player.model):
		player.model.set_glow(glow_color, 0.0)
	super()


## ¿Está con la rabia?
func is_raging() -> bool:
	return _left > 0.0


## ¿Ya la gastó en esta partida?
func is_used() -> bool:
	return _used


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		_calm_down()


## Un golpe lo iba a matar: la primera vez, se enfurece y no muere.
func _on_lethal_hit() -> bool:
	if _used:
		return false
	_used = true
	_left = duration
	player.health.floor_health = 1.0
	for stat: StringName in boosted_stats:
		player.stats.add_modifier(StatModifier.create(stat, StatModifier.Kind.MULTIPLIER, boost), self)
	player.model.set_glow(glow_color, glow_energy)
	if not announce_key.is_empty():
		EventBus.announced.emit(announce_key, [], glow_color)
	set_process(true)
	return true


func _calm_down() -> void:
	_left = 0.0
	set_process(false)
	player.health.floor_health = 0.0
	player.stats.remove_modifiers_from(self)
	player.model.set_glow(glow_color, 0.0)
