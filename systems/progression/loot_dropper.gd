class_name LootDropper
extends Node
## Lo que sueltan los enemigos al morir (escucha [code]EventBus.enemy_died[/code]): de momento, una
## gema con su experiencia ([member EnemyStats.xp_reward]). Fichas, cofres y probabilidades de botín
## llegarán aquí.

## Dónde caen los recogibles.
@export var field: PickupField
## Recogible de la experiencia.
@export var xp_gem: PickupData


func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)


func _on_enemy_died(enemy: Enemy) -> void:
	var xp := enemy.xp_reward()
	if xp > 0.0:
		field.drop(xp_gem, enemy.global_position, xp)
