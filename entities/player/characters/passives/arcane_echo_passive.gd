class_name ArcaneEchoPassive
extends CharacterPassive
## Eco arcano (Mago): cada [member every] ataques de un arma, el último sale dos veces (suma tantos
## golpes como tiene el ataque). Cuenta cada arma por separado, también las que consiga después.

## Cada cuántos ataques de un arma hay eco.
@export_range(2, 20, 1) var every: int = 2

## Ataques de cada arma (por id de instancia) desde su último eco.
var _counts: Dictionary[int, int] = {}


func _activated() -> void:
	player.weapons.weapon_added.connect(_watch)
	for weapon: Weapon in player.weapons.get_weapons():
		_watch(weapon)


func _watch(weapon: Weapon) -> void:
	weapon.attack_started.connect(_on_attack_started.bind(weapon))


func _on_attack_started(weapon: Weapon) -> void:
	var id := weapon.get_instance_id()
	var count: int = _counts.get(id, 0) + 1
	if count >= every:
		count = 0
		weapon.add_shots(weapon.projectile_count())
	_counts[id] = count
