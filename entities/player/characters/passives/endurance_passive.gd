class_name EndurancePassive
extends CharacterPassive
## Aguante (Guerrero): más daño cuantos más enemigos tiene cerca. Cada [member check_interval]
## cuenta las hurtbox de enemigos a menos de [member radius] y suma [member damage_per_enemy] de
## daño por cada una, hasta [member max_enemies].

## Capas de los enemigos que cuenta ([code]enemy_hurtbox[/code]).
@export_flags_3d_physics var enemy_mask: int = 0
## Distancia a la que cuenta enemigos.
@export_range(0.5, 30.0, 0.5, "suffix:m") var radius: float = 0.0
## Daño extra por cada enemigo cerca (0,02 = +2 %).
@export_range(0.0, 1.0, 0.005) var damage_per_enemy: float = 0.0
## Enemigos que cuentan como mucho.
@export_range(1, 100, 1) var max_enemies: int = 1
## Segundos entre cuentas.
@export_range(0.05, 2.0, 0.05, "suffix:s") var check_interval: float = 0.25
## Altura sobre los pies desde la que cuenta (el pecho).
@export_range(0.0, 3.0, 0.05, "suffix:m") var center_height: float = 1.0

var _finder: TargetFinder
var _left: float = 0.0
var _count: int = 0


func _activated() -> void:
	_finder = TargetFinder.new(enemy_mask)


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_left -= delta
	if _left > 0.0:
		return
	_left = check_interval
	var center := player.global_position + Vector3.UP * center_height
	var count := _finder.nearest(player.get_world_3d().direct_space_state, center, radius, max_enemies).size()
	if count != _count:
		_count = count
		_set_bonus(&"damage", StatModifier.Kind.PERCENT, damage_per_enemy * count)


## Enemigos cerca en la última cuenta.
func get_count() -> int:
	return _count
